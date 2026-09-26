#!/usr/bin/env python3
"""Render the production Prepare progress bar in an isolated simulator app."""

from pathlib import Path
import argparse
import plistlib
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("simulator")
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
source = (repo / "lara/views/new/EagleRainbowLoadingView.swift").read_text()
bar = source[source.index("struct EagleRainbowProgressBar:"):source.index("private func eagleRainbowPhase")]
work = Path(tempfile.mkdtemp(prefix="eagle-rainbow-preview-"))
app = work / "RainbowPreview.app"
app.mkdir()
(app / "Info.plist").write_bytes(plistlib.dumps({
    "CFBundleIdentifier": "local.eagle.rainbow-preview",
    "CFBundleExecutable": "RainbowPreview",
    "CFBundleName": "Rainbow Preview",
    "CFBundlePackageType": "APPL",
    "CFBundleVersion": "1",
    "CFBundleShortVersionString": "1",
    "MinimumOSVersion": "16.0",
    "UIDeviceFamily": [1],
    "UILaunchScreen": {},
}))
swift = work / "Preview.swift"
swift.write_text("""
import SwiftUI
enum LaraL10n { static func text(en: String, es: String) -> String { en } }
""" + bar + """
@main struct RainbowPreviewApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading, spacing: 22) {
                Text("Prepare").font(.title.bold())
                Text("Preparing device").foregroundStyle(.secondary)
                EagleRainbowProgressBar(value: 0.60, height: 6)
            }
            .padding(28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
            .preferredColorScheme(.dark)
        }
    }
}
""")
sdk = subprocess.check_output(["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], text=True).strip()
subprocess.run(["xcrun", "swiftc", "-parse-as-library", "-swift-version", "5", "-target",
                "arm64-apple-ios16.0-simulator", "-sdk", sdk, str(swift),
                "-o", str(app / "RainbowPreview")], check=True)
subprocess.run(["codesign", "--force", "--sign", "-", str(app)], check=True)
subprocess.run(["xcrun", "simctl", "install", args.simulator, str(app)], check=True)
print("PREVIEW_APP:", app)
