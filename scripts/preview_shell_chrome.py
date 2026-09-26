#!/usr/bin/env python3
"""Render the production app shell with safe, simulated page content."""
from pathlib import Path
import argparse
import plistlib
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("simulator")
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
source = (repo / "lara/views/new/EagleAppShellView.swift").read_text()
shell = source[:source.index("private struct TelegramSafariView:")]
stub = r'''
private struct MediaPreviewKey: EnvironmentKey {
    static let defaultValue = true
}
extension EnvironmentValues {
    var laraMediaPreviewsEnabled: Bool {
        get { self[MediaPreviewKey.self] }
        set { self[MediaPreviewKey.self] = newValue }
    }
}
final class EagleSceneManager: ObservableObject {
    static let shared = EagleSceneManager()
    @Published var notice: Notice?
    var isApplying = false
    var progress = 0.0
}
final class EagleNotifications: ObservableObject {
    static let shared = EagleNotifications()
    var visible = false
}
struct Notice { let message: String }
extension View {
    func eagleNotice(item: Binding<Notice?>, title: String,
                     message: (Notice) -> String) -> some View { self }
}
enum LaraL10n {
    static func text(en: String, es: String) -> String { en }
}
struct EagleBlockingProgress: View {
    let title: String
    let progress: Double
    var body: some View { EmptyView() }
}
struct EagleBeta10AccessView: View {
    var body: some View { page(title: "Access") }
}
struct LaraHomeView: View {
    var body: some View { page(title: "Customize") }
}
func page(title: String) -> some View {
    NavigationStack {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(title).font(.largeTitle.bold())
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        .frame(height: 360)
                    ForEach(0..<16, id: \.self) { index in
                        Text("Option \(index + 1)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(Color.blue.opacity(0.35), in: RoundedRectangle(cornerRadius: 16))
                            .id(index)
                    }
                }
                .padding(20)
            }
            .onAppear { proxy.scrollTo(15, anchor: .bottom) }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
    }
    .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
}
@main struct ShellPreview: App {
    var body: some Scene {
        WindowGroup {
            EagleAppShellView()
                .preferredColorScheme(CommandLine.arguments.contains("--light") ? .light : .dark)
        }
    }
}
'''
with tempfile.TemporaryDirectory(prefix="eagle-shell-preview-") as temporary:
    work = Path(temporary)
    app = work / "ShellPreview.app"
    app.mkdir()
    swift = work / "ShellPreview.swift"
    swift.write_text(shell + stub)
    (app / "Info.plist").write_bytes(plistlib.dumps({
        "CFBundleIdentifier": "local.eagle.shell-preview",
        "CFBundleExecutable": "ShellPreview", "CFBundleName": "Shell Preview",
        "CFBundlePackageType": "APPL", "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1", "MinimumOSVersion": "16.0",
        "UIDeviceFamily": [1], "UILaunchScreen": {},
        "UIApplicationSceneManifest": {"UIApplicationSupportsMultipleScenes": False},
    }))
    sdk = subprocess.check_output(
        ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], text=True
    ).strip()
    subprocess.run([
        "xcrun", "swiftc", "-parse-as-library", "-swift-version", "5",
        "-target", "arm64-apple-ios16.0-simulator", "-sdk", sdk,
        str(swift), "-o", str(app / "ShellPreview")
    ], check=True)
    subprocess.run(["codesign", "--force", "--sign", "-", str(app)], check=True)
    subprocess.run(["xcrun", "simctl", "install", args.simulator, str(app)], check=True)
    print("PREVIEW_APP:", app)
