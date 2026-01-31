import SwiftUI

struct OptionalDatePicker: View {

    let label: String
    let prompt: String
    @Binding var date: Date?
    @State private var hidenDate: Date = Date()

    init(_ label: String, prompt: String, selection: Binding<Date?>) {
        self.label = label
        self.prompt = prompt
        self._date = selection
    }

    var body: some View {
        ZStack {
            HStack {
                Text(label)
                    .multilineTextAlignment(.leading)
                Spacer()
                if date != nil {
                    Button {
                        date = nil
                    } label: {
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                    DatePicker(
                        label,
                        selection: $hidenDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .onChange(of: hidenDate) { _, newDate in
                        date = newDate
                    }

                } else {
                    Button {
                        date = hidenDate
                    } label: {
                        Text(prompt)
                            .multilineTextAlignment(.trailing)

                    }
                }
            }
        }.onAppear {
            self.hidenDate = date ?? Date()
        }
    }
}
