import SwiftUI
import AuthenticationServices
import CryptoKit

/// Login / registration view shared by macOS and iOS.
public struct LoginView: View {
    @EnvironmentObject var viewModel: ReaderViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var currentNonce: String?

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            // App icon + title
            VStack(spacing: 8) {
                if let icon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 64, height: 64)
                }
                Text("NewReader")
                    .font(.largeTitle.bold())
                Text("AI 阅读伴侣")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)

            if viewModel.authService.isInitializing {
                ProgressView("正在初始化…")
                    .padding(.vertical, 20)
            } else {
                loginForm
            }
        }
        .padding()
        .frame(minWidth: 380, minHeight: 460)
    }

    private var loginForm: some View {
        VStack(spacing: 12) {
            TextField("邮箱", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .disabled(isLoading)

            SecureField("密码", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .disabled(isLoading)

            // Error
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: 320, alignment: .leading)
                    .padding(.vertical, 4)
            }

            // Email action button
            Button(action: submit) {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("处理中…")
                    }
                    .frame(maxWidth: 320)
                } else {
                    Text(isSignUp ? "注册" : "登录")
                        .frame(maxWidth: 320)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(email.isEmpty || password.isEmpty || isLoading || viewModel.authService.isInitializing)
            .keyboardShortcut(.return, modifiers: [])

            Button(isSignUp ? "已有账号？登录" : "没有账号？注册") {
                isSignUp.toggle()
                errorMessage = nil
            }
            .buttonStyle(.link)
            .font(.caption)
            .disabled(isLoading)

            // Divider
            HStack(spacing: 12) {
                VStack { Divider() }
                Text("或").font(.caption).foregroundStyle(.tertiary)
                VStack { Divider() }
            }
            .frame(maxWidth: 320)
            .padding(.vertical, 8)

            // Sign in with Apple
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email, .fullName]
                let raw = randomNonce(); currentNonce = raw; request.nonce = sha256(raw)
            } onCompletion: { result in
                handleAppleResult(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(maxWidth: 320)
            .frame(height: 40)
            .disabled(isLoading || viewModel.authService.isInitializing)
        }
        .frame(maxWidth: 320)
    }

    // MARK: - Email submit

    private func submit() {
        guard !email.isEmpty, !password.isEmpty else { return }
        print("[LoginView] submit: isSignUp=\(isSignUp), email=\(email)")
        isLoading = true
        errorMessage = nil

        Task {
            do {
                if isSignUp {
                    try await viewModel.authService.signUp(email: email, password: password)
                    if viewModel.authService.isLoggedIn {
                        print("[LoginView] signUp success")
                    } else {
                        errorMessage = "注册请求已发送，请查看邮箱中的确认链接"
                    }
                } else {
                    try await viewModel.authService.signIn(email: email, password: password)
                    print("[LoginView] signIn success, isLoggedIn=\(viewModel.authService.isLoggedIn)")
                }
            } catch {
                let msg = error.localizedDescription
                print("[LoginView] auth error: \(msg)")
                errorMessage = msg
            }
            isLoading = false
        }
    }

    // MARK: - Apple Sign In

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let idToken = credential.identityToken,
                  let tokenString = String(data: idToken, encoding: .utf8) else {
                errorMessage = "Apple 登录失败：无法获取身份令牌"
                return
            }
            guard let nonce = currentNonce else {
                errorMessage = "Apple 登录失败：内部错误"
                return
            }
            print("[LoginView] Apple sign in: got idToken")
            isLoading = true
            errorMessage = nil

            Task {
                do {
                    try await viewModel.authService.signInWithApple(
                        idToken: tokenString,
                        nonce: nonce
                    )
                    print("[LoginView] Apple sign in success")
                } catch {
                    let msg = error.localizedDescription
                    print("[LoginView] Apple sign in error: \(msg)")
                    errorMessage = msg
                }
                isLoading = false
            }

        case .failure(let error):
            print("[LoginView] Apple sign in cancelled/error: \(error)")
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Nonce helpers

    private func randomNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: remaining)
            let err = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if err != errSecSuccess {
                fatalError("Unable to generate nonce")
            }
            for byte in randoms {
                if remaining == 0 { break }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#if DEBUG
#Preview {
    Text("LoginView Preview")
}
#endif
