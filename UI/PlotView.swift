import SwiftUI

struct PlotView: View {
    let values: [Int]
    var body: some View {
        GeometryReader { geo in
            let maxV = max(values.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 1) {
                ForEach(values.indices, id: \.self) { i in
                    let h = CGFloat(values[i]) / CGFloat(maxV) * geo.size.height
                    Rectangle()
                        .frame(width: max(1, geo.size.width / CGFloat(values.count) - 1), height: h)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
    }
}
