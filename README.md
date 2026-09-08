<div align="center">
  <img src="lara/other/media.xcassets/AppIcon.appiconset/P1ck4x3-Icon.png" alt="P1ck4x3 app icon" width="152" height="152">

  # ⚡ P1ck4x3

  **P1ck4x3 is a wild experimental iOS customization toolbox powered by DarkSword.**

  Unleash your iPhone's potential with P1ck4x3! Customize wallpapers, passcode themes, Wallet cards, Home Screen vibes, Dynamic Island flair, and Dock layouts from one insanely powerful app. Built for sideloaders who want complete control. ⚙️✨

  [![Latest release](https://img.shields.io/github/v/release/Nnnnnnn274/P1ck4x3?sort=semver&style=for-the-badge&label=LATEST%20RELEASE&color=7C3AED)](https://github.com/Nnnnnnn274/P1ck4x3/releases)
  [![Total IPA downloads](https://img.shields.io/github/downloads/Nnnnnnn274/P1ck4x3/total?style=for-the-badge&logo=icloud&logoColor=white&label=IPA%20DOWNLOADS&color=0891B2)](https://github.com/Nnnnnnn274/P1ck4x3/releases)
  [![GitHub stars](https://img.shields.io/github/stars/Nnnnnnn274/P1ck4x3?style=for-the-badge&logo=github&label=STARS&color=F59E0B)](https://github.com/Nnnnnnn274/P1ck4x3/stargazers)
  [![AGPL-3.0](https://img.shields.io/github/license/Nnnnnnn274/P1ck4x3?style=for-the-badge&label=LICENSE&color=16A34A)](LICENSE)

  <br>

  <a href="https://github.com/Nnnnnnn274/P1ck4x3/releases">
    <img src="https://img.shields.io/badge/DOWNLOAD_P1CK4X3.IPA-NOW-7C3AED?style=for-the-badge&logo=apple&logoColor=white" alt="Download P1ck4x3 IPA" height="48">
  </a>

  <br><br>

  [Release notes](https://github.com/Nnnnnnn274/P1ck4x3/releases)
  · [Report a bug](https://github.com/Nnnnnnn274/P1ck4x3/issues/new?template=bug_report.md)
  · [Request a feature](https://github.com/Nnnnnnn274/P1ck4x3/issues/new?template=feature_request.md)

  <sub>The IPA is unsigned. Sign it with your usual personal-device installation method.</sub>
</div>

---

## At a glance

| | |
|---|---|
| **Current release** | P1ck4x3 Latest Build |
| **Primarily verified on** | iPhone 16 Pro (`iPhone17,1`) · iOS 18.6.2 (`22G100`) |
| **Architecture** | `arm64e` |
| **Key Features** | Dynamic Island, Dock, Wallpapers, Passcode themes, Wallet cards · isolated apply and verification |
| **Project status** | Experimental · test one change at a time |

> [!WARNING]
> P1ck4x3 uses kernel-level and private SpringBoard capabilities. An incompatible
> operation can respring or reboot the device. Back up important data, test one
> change at a time and do not treat this as production-safe.

## What P1ck4x3 includes

| Experience | What it does |
|---|---|
| 🎨 **Styles** | Coordinates wallpaper, passcode and Wallet-card experiences. |
| 🌌 **Wallpapers** | Browses community packs, imports compatible packages and converts videos. |
| 💳 **Cards** | Previews, applies, backs up and restores supported Wallet card artwork. |
| 🔢 **Passcode** | Browses, imports, previews, applies and restores compatible key themes. |
| 🧩 **Icon Studio** | Custom icon shapes and theme importing (experimental). |
| 📱 **Dock** | Provides layouts supporting up to six apps where SpringBoard accepts them. |
| ✨ **Aura Studio** | Applies independently colored Dynamic Island and Dock lighting. |
| 🖼️ **Island Gallery** | Applies calibrated photo styles at verified size and position. |
| 🌈 **Dock Gallery** | Places exact-size artwork behind Dock apps without stretching. |
| 🔤 **App Name Color** | Applies solid color to app names on the current Home Screen page. |
| 🛡️ **P1ck4x3 System** | Guardian checks, Scenes and shareable personalization recipes. |

## Install P1ck4x3

1. Use the **Download P1ck4x3.ipa** button at the top of this page.
2. Sign the unsigned IPA with your preferred personal-device sideloading method.
3. Install it and open P1ck4x3 manually from the Home Screen.
4. If you installed through Xcode, press **Stop** before preparing access.
5. Apply one feature at a time and keep the exact result message if something fails.

Looking for an older build? Browse [all P1ck4x3 releases](https://github.com/Nnnnnnn274/P1ck4x3/releases).

## Compatibility and current limits

- **Prepare support:** iOS 16.x has limited testing (16.7.2 is the verified limited route);
  iOS 17.0–18.7.1 and 26.0–26.0.1 are accepted.
- Unverified iOS 16 builds, releases outside the supported ranges above and
  current MIE devices are blocked.
- iPhone 16 (`iPhone17,3`) running iOS 18.5 follows the supported Prepare route.
- Aura Studio live changes remain limited to verified iOS 17/18 SpringBoard routes.
- If Island Aura reports **Safe Compact Halo**, it will not expand with music,
  screen recording or timers. Only **Adaptive Aura** follows those layouts.
- Screen, Battery Halo and Lock experiments are hidden while their live
  SpringBoard hosts remain unverified.
- Dock and Dynamic Island Aura include dedicated geometry for iPhone 14 Pro,
  iPhone 14 Pro Max and the primary iPhone 16 Pro reference profile. Other
  supported models may still require model-specific validation.
- Icon importing, nonstandard masks and community packages remain dependent on
  device, iOS version and package structure.
- Kernel or SpringBoard operations are intentionally blocked while the Xcode
  debugger is attached.

Device strings such as `iPhone15,2` are Apple's technical model identifiers
(`iPhone15,2` is an iPhone 14 Pro), not the marketing generation number.

## Build from source

Requirements:

- macOS with Xcode
- the `codesign` tool included with macOS/Xcode

Compile without installing on a device:

```sh
xcodebuild -project lara.xcodeproj \
  -scheme lara \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO build
```

Package the release IPA:

```sh
./scripts/build_ipa.sh
```

The result is written to `build/P1ck4x3.ipa`.

## Report a problem

Open the [guided bug report](https://github.com/Nnnnnnn274/P1ck4x3/issues/new?template=bug_report.md)
and include:

- exact iPhone or iPad model;
- iOS version and build number;
- P1ck4x3 version or commit;
- feature and selected mode;
- exact result message;
- the shareable Prepare or Aura diagnostic report when P1ck4x3 offers one;
- a full-width screenshot when the problem is visual;
- the relevant end of `Documents/lara.log`, with personal paths removed.

Do not publish tokens, certificates, provisioning profiles or unrelated personal files.

## Project lineage, license and acknowledgements

P1ck4x3 is a modified version of [Lara](https://github.com/rooootdev/lara). The
P1ck4x3 interface and feature set began diverging from Lara in 2026.

P1ck4x3 is licensed as a whole under [GNU AGPL-3.0](LICENSE), preserving Lara's
license and notices. Source distributions and modified builds must continue to
comply with that license.

Core acknowledgements include the Lara contributors, rooootdev, opa334, ChOma,
XPF, AlfieCG/libgrabkernel2, DarkSword contributors, AppInstaller iOS and the
upstream projects whose notices remain in [`lara/licenses`](lara/licenses).

---

<div align="center">
  <strong>P1ck4x3</strong> · extreme iOS customization, verified and safe
  <br>
  <sub>Built with Swift, SwiftUI and DarkSword. 🚀</sub>
</div>