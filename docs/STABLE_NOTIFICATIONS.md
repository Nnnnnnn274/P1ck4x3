# Public baseline + positioning + native notifications

Base: public Eagle 1.0.4, commit `c16abaa` (build 80), confirmed latest public release on 2026-09-21.
Branch: `feature/stable-notifications`. The previous private Island Glass worktree is preserved separately; it is not part of this build.

## Scope

- Restore only gallery positioning from `16fc57c`: four directions, 0.25/0.5/1-point steps, reset, separate saved Dock/Island offsets, finite values clamped to ±12 points. Offsets move Eagle's theme, not the hardware cutout or system icons. Apply the theme to commit its previewed position.
- Native in-app completion notifications ported from rit3zh/expo-dynamic-notifications. SwiftUI/UIKit/Core Image only, with the original black island, black-to-white droplet, white capsule and blue accent. MIT attribution included in Credits and licenses. These are not system-wide notifications or Live Activities.
- Result presentation for galleries, Aura, Hide surfaces, Prepare, styles/scenes, fonts, wallpapers, and utility actions. Confirmations, destructive choices and respring prompts remain native dialogs. Optional wallpaper/settings and style-detail actions remain accessible from the notice.
- Boolean result callbacks use success/error icons; legacy message-only results are informational, never guessed to be successes.
- No changes to exploit, Prepare engine, compatibility matrices, remote-session gates, downloads, catalog, or theme application algorithms. `rc.m` changes only add and consume bounded gallery position offsets.

## Runtime cost and interaction

No Expo, React Native, Skia, downloaded notification assets, polling or persistent display timers. One visible notice and at most one pending completion. A new result first returns the old droplet to the island, then enters. Backgrounding or dismissal releases the overlay window. The non-key window passes touches outside the card through to Eagle. Tap runs the optional action and dismisses; upward swipe dismisses. VoiceOver reads the complete message. Supports Dynamic Type and Reduce Motion.

The overlay starts at screen y=0 rather than at the safe area. Geometry, neck profile, 126 × 37.33-point island, 52-point droplet, 34-point gap, 74-point normal card, 110/340/560ms entry staging and 100/280ms exit staging come from the reference. Core Image executes the same rounded-shape → 14.3-point blur → 22× alpha gain/0.43 cutoff pipeline as the Skia source. Reanimated 4.5's duration-spring stiffness calculation is ported by formula instead of approximated with SwiftUI `response:`. A native light visual-effect layer matches the source content reveal. This is a native port, not execution of the React Native project, and its filtered surface covers only the header.

## Full Island interaction revision (2026-09-22)

The user rejected the simplified floating toast. It is replaced by the full morph overlay, with a neck that stretches and breaks, tint transition, blur reveal, collapse and return. No Prepare, gallery runtime or exploit code changed in this revision.

Passed: release build and signing/ZIP checks; reference geometry fixtures; 3,710 width/inset/spring samples; queued replacement, dismissal, expiry, background teardown, key-window and touch-passthrough assertions; existing gallery regression scripts. Recorded and inspected animation frames for entrance and return, plus frozen intermediate geometry snapshots. Device testing remains required.

The visual-parity revision was simulator-compiled and reran the isolated lifecycle, queue, expiry, teardown and touch-passthrough checks. No IPA was generated for this revision, per request.

Current private IPA: build/Eagle-Island-Notifications.ipa (18,274,679 bytes). The earlier simplified IPA is retained under its old filename; it is not the current test build. The following September 21 notes describe that earlier build.

## Checks

- Release device compilation and private IPA packaging.
- `verify_gallery_session_lifetime.py`, `verify_island_apply_gate.py`, `verify_remote_operation_ownership.py`, and compiled `verify_gallery_position.c`.
- Existing Prepare matrix and kernel-pointer guard checks run by `scripts/build_ipa.sh`.
- Isolated simulator lifecycle/touch tests: `bash scripts/verify_dynamic_notifications.sh <booted-simulator-UUID>`. Wait for PASS; the harness then leaves a sample notice on screen. It does not include or exercise the access engine.

Physical-device application of Dock/Island themes and hide/restore operations still requires user testing before publication. Compilation and simulator checks do not prove every supported iPhone/iOS combination stable. No public release is made by this task.

## Recorded validation (2026-09-21)

Release build, embedded/main ad-hoc signature verification, ZIP integrity, the listed regression checks, and simulator notification assertions passed. Normal and accessibility-extra-large text were visually checked; the simulator's previous text setting was restored. The notification hit-region check initially failed during development and passed after replacing the transient preference measurement with per-card geometry updates.

Private artifact: `build/Eagle-Stable-Notifications.ipa`, 18,284,500 bytes. Public `Eagle-1.0.4-80.ipa` asset reported by GitHub: 18,155,055 bytes. This entire build adds 129,445 bytes (about 0.71%); that is a package comparison, not a measured RAM/battery benchmark. The notification test app is not included in the IPA.
