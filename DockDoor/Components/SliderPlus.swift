import SwiftUI

struct SliderPlus: View {
    @Binding var value: Double

    var range: ClosedRange<Double>
    var rangeManual: ClosedRange<Double>?
    var step: Double = 1
    var measureType: String? = nil
    var maxWidth: Double = 200
    var useTickMarks: Bool?

    init(value: Binding<Double>, range: ClosedRange<Double>, rangeManual: ClosedRange<Double>? = nil, step: Double = 1, measureType: String? = nil) {
        _value = value
        self.range = range
        self.rangeManual = rangeManual
        self.step = step
        self.measureType = measureType
    }

    init(value: Binding<CGFloat>, range: ClosedRange<Double>, rangeManual: ClosedRange<Double>? = nil, step: Double = 1, measureType: String? = nil, useTickMarks: Bool? = nil) {
        _value = Binding<Double>(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = CGFloat($0) }
        )
        self.range = range
        self.rangeManual = rangeManual
        self.step = step
        self.measureType = measureType
        self.useTickMarks = useTickMarks
    }

    init(value: Binding<Int>, range: ClosedRange<Double>, rangeManual: ClosedRange<Double>? = nil, step: Double = 1, measureType: String? = nil, useTickMarks: Bool? = nil) {
        _value = Binding<Double>(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = Int($0) }
        )
        self.range = range
        self.rangeManual = rangeManual
        self.step = step
        self.measureType = measureType
        self.useTickMarks = useTickMarks
    }

    func getSafeRange(_ r: ClosedRange<Double>) -> ClosedRange<Double> {
        var lower = r.lowerBound
        var upper = r.upperBound
        if lower < 0 { lower = 0 }
        if upper <= lower { upper = max(value, lower) }
        if upper <= lower { upper += 1 }
        return lower ... upper
    }

    var safeRange: ClosedRange<Double> { getSafeRange(range) }

    var safeRangeManual: ClosedRange<Double>? {
        guard let rangeManual else { return nil }
        return getSafeRange(rangeManual)
    }

    var rangeAmount: Double { safeRange.upperBound - safeRange.lowerBound }

    var safeStep: Double { rangeAmount < step ? rangeAmount : step }

    var body: some View {
        let rangeManual = safeRangeManual ?? safeRange

        HStack {
            Group {
                if let useTickMarks {
                    if useTickMarks {
                        // tick marks style
                        Slider(value: $value, in: safeRange, step: safeStep)
                    } else {
                        Slider(
                            value: Binding(
                                get: { value },
                                set: { newValue in
                                    let base = Int(newValue.rounded())
                                    let modulo: Int = base % Int(step)
                                    value = Double(base - modulo)
                                }
                            ),
                            in: safeRange
                        )
                    }
                } else {
                    if (rangeAmount / step) <= 20 {
                        // tick marks style
                        Slider(value: $value, in: safeRange, step: safeStep)
                    } else {
                        Slider(
                            value: Binding(
                                get: { value },
                                set: { newValue in
                                    let base = Int(newValue.rounded())
                                    let modulo: Int = base % Int(step)
                                    value = Double(base - modulo)
                                }
                            ),
                            in: safeRange
                        )
                    }
                }
            }
            .frame(maxWidth: maxWidth)

            HStack {
                Group {
                    if step.truncatingRemainder(dividingBy: 1) != 0 {
                        TextField("", value: $value, formatter: decimalFormatter)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        IntegerTextField(value: $value, minVal: rangeManual.lowerBound, maxVal: rangeManual.upperBound)
                    }
                }
                .frame(width: 40, height: 0)
                if let measureType {
                    Text(measureType)
                        .font(.system(size: 12))
                        .opacity(0.5)
                }
            }
        }
    }
}

struct IntegerTextField: NSViewRepresentable {
    @Binding var value: Double
    var minVal: CGFloat
    var maxVal: CGFloat

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.alignment = .center
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.delegate = context.coordinator
        textField.isBezeled = true
        textField.bezelStyle = .roundedBezel
        textField.isEditable = true
        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = String(format: "%.0f", value) // Format as integer
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: IntegerTextField

        init(_ parent: IntegerTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                if let intValue = Double(textField.stringValue) {
                    let clampedValue = min(max(CGFloat(intValue), parent.minVal), parent.maxVal)
                    parent.value = clampedValue
                } else {
                    parent.value = Double(Int(parent.minVal)) // Reset to min if invalid input
                }
            }
        }

        func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
            let allowedCharacters = CharacterSet(charactersIn: "0123456789")
            let characterSet = CharacterSet(charactersIn: fieldEditor.string)
            return allowedCharacters.isSuperset(of: characterSet)
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                control.window?.makeFirstResponder(nil) // Resign first responder to lose focus
                return true
            }
            return false
        }
    }
}
