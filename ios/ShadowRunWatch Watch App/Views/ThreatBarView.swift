import SwiftUI

struct ThreatBarView: View {
    let threatLevel: String
    let percent: Double

    var threatColor: Color {
        switch threatLevel {
        case "aheadFar", "aheadMid", "aheadClose": return .green
        case "safe": return .blue
        case "warningFar", "warningClose": return .yellow
        case "dangerFar", "dangerClose": return .orange
        case "critical": return .red
        default: return .gray
        }
    }

    var threatLabel: String {
        switch threatLevel {
        case "aheadFar": return "SAFE"
        case "aheadMid": return "AHEAD"
        case "aheadClose": return "AHEAD"
        case "safe": return "SAFE"
        case "warningFar": return "WARNING"
        case "warningClose": return "WARNING"
        case "dangerFar": return "DANGER"
        case "dangerClose": return "DANGER!"
        case "critical": return "CRITICAL"
        default: return "---"
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(threatLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(threatColor)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(threatColor)
                        .frame(width: geo.size.width * min(max(percent, 0), 1))
                        .animation(.easeInOut(duration: 0.3), value: percent)
                }
            }
            .frame(height: 6)
        }
    }
}
