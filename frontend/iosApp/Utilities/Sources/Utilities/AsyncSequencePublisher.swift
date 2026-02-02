import Foundation
import Combine

/// Converts an AsyncSequence to a Combine Publisher
public struct AsyncSequencePublisher<S: AsyncSequence>: Publisher where S.Element: Sendable, S: Sendable {
    public typealias Output = S.Element
    public typealias Failure = Never

    private let sequence: S

    public init(_ sequence: S) {
        self.sequence = sequence
    }

    public func receive<Sub>(subscriber: Sub) where Sub: Subscriber, Sub.Failure == Never, Sub.Input == Output {
        let subscription = AsyncSequenceSubscription(sequence: sequence, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

private final class AsyncSequenceSubscription<S: AsyncSequence, Sub: Subscriber>: Subscription, @unchecked Sendable
    where Sub.Input == S.Element, Sub.Failure == Never, S.Element: Sendable, S: Sendable {

    private var task: Task<Void, Never>?
    private let sequence: S
    private let subscriber: Sub

    init(sequence: S, subscriber: Sub) {
        self.sequence = sequence
        self.subscriber = subscriber
        startTask()
    }

    private func startTask() {
        // Capture locally to avoid capturing self in the Task
        let subscriber = self.subscriber
        let sequence = self.sequence

        task = Task {
            do {
                for try await element in sequence {
                    guard !Task.isCancelled else { break }
                    _ = subscriber.receive(element)
                }
                subscriber.receive(completion: .finished)
            } catch {
                // AsyncSequence threw an error, complete
                subscriber.receive(completion: .finished)
            }
        }
    }

    func request(_ demand: Subscribers.Demand) {
        // Unlimited demand - we emit as fast as the sequence produces
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

extension AsyncSequence where Element: Sendable, Self: Sendable {
    /// Converts this AsyncSequence to a Combine Publisher
    public func asPublisher() -> AnyPublisher<Element, Never> {
        AsyncSequencePublisher(self).eraseToAnyPublisher()
    }
}
