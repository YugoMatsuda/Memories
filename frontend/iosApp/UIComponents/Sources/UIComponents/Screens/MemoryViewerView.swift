import SwiftUI
import SDWebImageSwiftUI
import UILogics

public struct MemoryViewerView: View {
    @Binding var viewerMemoryId: UUID?
    let items: [AlbumDetailViewModel.MemoryItemUIModel]

    @State private var currentPosition: UUID?
    @State private var opacity: Double = 0

    public init(
        viewerMemoryId: Binding<UUID?>,
        items: [AlbumDetailViewModel.MemoryItemUIModel]
    ) {
        self._viewerMemoryId = viewerMemoryId
        self.items = items
    }

    public var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(items) { item in
                    GeometryReader { geo in
                        let size = geo.size
                        WebImage(url: item.displayImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: size.width, height: size.height)
                    }
                    .containerRelativeFrame(.horizontal)
                    .id(item.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $currentPosition)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .background(.black)
        .opacity(opacity)
        .overlay(alignment: .topLeading) {
            closeButton
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 12) {
                pageIndicator
                if let item = currentItem {
                    titleOverlay(item: item)
                }
            }
        }
        .onAppear {
            currentPosition = viewerMemoryId
            withAnimation(.easeInOut(duration: 0.25)) {
                opacity = 1
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.height > 100 {
                        close()
                    }
                }
        )
    }

    private var closeButton: some View {
        Button {
            close()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white.opacity(0.8), .white.opacity(0.15))
        }
        .padding()
        .opacity(opacity)
    }

    private func titleOverlay(item: AlbumDetailViewModel.MemoryItemUIModel) -> some View {
        VStack(spacing: 4) {
            Text(item.title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(item.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .opacity(opacity)
    }

    private var currentItem: AlbumDetailViewModel.MemoryItemUIModel? {
        items.first { $0.id == currentPosition }
    }

    private var currentIndex: Int {
        items.firstIndex { $0.id == currentPosition } ?? 0
    }

    @ViewBuilder
    private var pageIndicator: some View {
        if items.count > 1 {
            HStack(spacing: 6) {
                ForEach(0..<items.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 8)
            .opacity(opacity)
        }
    }

    private func close() {
        withAnimation(.easeInOut(duration: 0.25)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            viewerMemoryId = nil
        }
    }
}
