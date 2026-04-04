import SwiftUI

enum ToastType {
    case success, error, info, warning

    var backgroundColor: Color {
        switch self {
        case .success: .appSuccess
        case .error: .appDanger
        case .info: .appPrimary
        case .warning: .appWarning
        }
    }

    var iconName: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .error: "xmark.circle.fill"
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        }
    }
}

struct ToastView: View {
    let message: String
    let type: ToastType

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type.iconName)
                .font(.body)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.backgroundColor, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        .padding(.horizontal, 16)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let type: ToastType

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if isShowing {
                ToastView(message: message, type: type)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isShowing = false
                            }
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
                    .zIndex(999)
            }
        }
        .animation(.spring(duration: 0.4, bounce: 0.2), value: isShowing)
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, type: ToastType = .info) -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, type: type))
    }
}

#Preview {
    struct Preview: View {
        @State private var showSuccess = false
        @State private var showError = false
        @State private var showInfo = false

        var body: some View {
            VStack(spacing: 16) {
                Button("Erfolg anzeigen") { showSuccess = true }
                Button("Fehler anzeigen") { showError = true }
                Button("Info anzeigen") { showInfo = true }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toast(isShowing: $showSuccess, message: "Erfolgreich gespeichert!", type: .success)
            .toast(isShowing: $showError, message: "Fehler beim Speichern.", type: .error)
            .toast(isShowing: $showInfo, message: "Neue Version verfügbar.", type: .info)
        }
    }
    return Preview()
}
