import Foundation

var decimalFormatter: NumberFormatter {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 1
    return formatter
}
