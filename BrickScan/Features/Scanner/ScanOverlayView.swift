import SwiftUI

struct ScanOverlayView: View {
    let state: ScannerState

    private var frameColor: Color {
        switch state {
        case .processing:
            return Color(hex: "FFD700")
        case .error:
            return Color(hex: "E3000B")
        case .found, .ambiguous:
            return .green
        default:
            return .white
        }
    }

    private var statusText: String {
        switch state {
        case .scanning:
            return "Scan en cours..."
        case .processing:
            return "Recherche..."
        case .found:
            return "Set détecté !"
        case .ambiguous:
            return "Plusieurs résultats trouvés"
        case .notFound:
            return "Set non trouvé. Essayez de scanner à nouveau."
        case .error(let message):
            return message
        case .permissionDenied:
            return "Accès caméra refusé"
        }
    }

    var body: some View {
        VStack {
            Text(statusText)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.black.opacity(0.6))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, 24)

            Spacer()

            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(frameColor, lineWidth: 3)
                .frame(width: 280, height: 180)
                .overlay {
                    if state == .processing {
                        ProgressView()
                            .tint(.white)
                    }
                }

            Spacer()

            Text("Pointez la caméra vers le code-barres ou le numéro de set")
                .font(.footnote)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
    }
}

extension Color {
    init(hex: String) {
        var hexValue = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexValue = hexValue.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexValue).scanHexInt64(&rgb)

        let red = Double((rgb & 0xFF0000) >> 16) / 255
        let green = Double((rgb & 0x00FF00) >> 8) / 255
        let blue = Double(rgb & 0x0000FF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}
