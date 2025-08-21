import SwiftUI

// MARK: - Data models

struct EQBand: Identifiable {
    let id = UUID()
    let label: String
    let gain: Double    
}

struct EQPreset: Identifiable {
    let id = UUID()
    let name: String
    let bands: [EQBand]
}

// MARK: - Chart (display-only)

struct EQChartView: View {
    let bands: [EQBand]

    private let minDB: Double = -12
    private let maxDB: Double =  12

    private let leftPad: CGFloat   = 46.fitW
    private let rightPad: CGFloat  = 12.fitW
    private let topPad: CGFloat    = 20.fitH
    private let bottomPad: CGFloat = -10.fitH

    private let innerXInset: CGFloat = 12.fitW
    private let innerYInset: CGFloat = 10.fitW

    private let endCapFactor: CGFloat = 0.5

    private func yPos(db: Double, innerH: CGFloat, plotTop: CGFloat) -> CGFloat {
        let t = (db - minDB) / (maxDB - minDB)
        return plotTop + (1 - CGFloat(t)) * innerH
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let outerW = max(w - leftPad - rightPad, 1)
            let outerH = max(h - topPad - bottomPad, 1)

            let plotLeft   = leftPad + innerXInset
            let plotRight  = leftPad + outerW - innerXInset
            let plotTop    = topPad  + innerYInset
            let plotBottom = topPad  + outerH - innerYInset

            let innerW = max(plotRight - plotLeft, 1)
            let innerH = max(plotBottom - plotTop, 1)

            let denom = CGFloat(max(bands.count - 1, 1))
            let safeStep = max(innerW / denom, 1)
            let endExtra = safeStep * endCapFactor - 5
            let yZero = yPos(db: 0, innerH: innerH, plotTop: plotTop)

            ZStack {
                Path { p in
                    let yTop = yPos(db: maxDB, innerH: innerH, plotTop: plotTop)
                    let yMid = yZero
                    let yBot = yPos(db: minDB, innerH: innerH, plotTop: plotTop)

                    p.move(to: CGPoint(x: plotLeft - endExtra, y: yTop))
                    p.addLine(to: CGPoint(x: plotRight + endExtra, y: yTop))

                    p.move(to: CGPoint(x: plotLeft - endExtra, y: yMid))
                    p.addLine(to: CGPoint(x: plotRight + endExtra, y: yMid))

                    p.move(to: CGPoint(x: plotLeft - endExtra, y: yBot))
                    p.addLine(to: CGPoint(x: plotRight + endExtra, y: yBot))
                }
                .stroke(.gray2C2C2C.opacity(0.8), lineWidth: 1)

                Path { p in
                    for i in bands.indices {
                        let x = plotLeft + CGFloat(i) * safeStep
                        p.move(to: CGPoint(x: x, y: plotTop))
                        p.addLine(to: CGPoint(x: x, y: plotBottom))
                    }
                }
                .stroke(.gray2C2C2C.opacity(0.8), lineWidth: 1)

                VStack {
                    Text("+12 dB")
                        .font(.manropeRegular(size: 12))
                        .foregroundStyle(.gray707070)
                        .padding(.top, -6.fitH)
                    Spacer()
                    Text("0 dB")
                        .font(.manropeRegular(size: 12))
                        .foregroundStyle(.gray707070)
                        .padding(.top, 6.fitH)
                    Spacer()
                    Text("-12 dB")
                        .font(.manropeRegular(size: 12))
                        .foregroundStyle(.gray707070)
                        .padding(.bottom, -6.fitH)
                }
                .frame(width: leftPad - 8, height: innerH) // safe innerH
                .position(x: (leftPad - 8)/2 - 10, y: plotTop + innerH/2)

                Path { path in
                    guard !bands.isEmpty else { return }
                    path.move(to: CGPoint(x: plotLeft - endExtra, y: yZero))
                    for i in bands.indices {
                        let x = plotLeft + CGFloat(i) * safeStep
                        path.addLine(to: CGPoint(x: x,
                                                 y: yPos(db: bands[i].gain, innerH: innerH, plotTop: plotTop)))
                    }
                    path.addLine(to: CGPoint(x: plotRight + endExtra, y: yZero))
                }
                .stroke(Color.blue, lineWidth: 2)

                ForEach(bands.indices, id: \.self) { i in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 9.fitW, height: 9.fitW)
                        .position(
                            x: plotLeft + CGFloat(i) * safeStep,
                            y: yPos(db: bands[i].gain, innerH: innerH, plotTop: plotTop)
                        )
                }

                HStack(spacing: 0) {
                    ForEach(bands) { b in
                        Text("\(Int(b.gain))dB")
                            .font(.manropeRegular(size: 12))
                            .foregroundStyle(.gray707070)
                            .frame(width: safeStep, height: innerYInset, alignment: .center)
                    }
                }
                .frame(width: innerW)
                .position(x: plotLeft + innerW/2, y: plotTop - innerYInset/2 - 10)

                HStack(spacing: 0) {
                    ForEach(bands) { b in
                        Text(b.label)
                            .font(.manropeRegular(size: 12))
                            .foregroundStyle(.gray707070)
                            .frame(width: safeStep, alignment: .center)
                    }
                }
                .frame(width: innerW)
                .position(x: plotLeft + innerW/2, y: plotBottom + innerYInset/2 + 10)
            }
        }
    }
}
