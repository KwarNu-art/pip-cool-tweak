# Pip

**Short. Cute. Honest.** A tiny jailbreak tweak for older iPhones — especially **iPhone 7 Plus**.

Pip does **not** promise “100% no heat” or “120 Hz forever.”  
Your 7 Plus screen is **60 Hz maximum**. Pip only **reduces work** so the phone stays cooler, lasts longer on battery, and freezes less often.

---

## What Pip does

| Feature | Reality |
|--------|---------|
| Floating **pip** pill (bottom, draggable) | Lives in UIKit apps when the tweak is injected |
| Tap → panel | Shows **FPS**, rough **CPU %**, **memory MB**, **thermal state** (Nominal / Fair / Serious / Critical) |
| FPS cap | **Off / 15 / 20 / 30 / 60** — never 120 on this hardware |
| Graphics level | Normal → Small → Smaller → Smallest (lower layer scale → less GPU fill) |
| Reduce blur | Softens heavy `UIVisualEffectView` blurs |
| Reduce animations | Cuts UIKit animation churn |
| Size goal | Small tweak; typical release **well under 1 MB** |

**Thermal “heat rate”** uses Apple’s public `NSProcessInfo.thermalState` — not a fake °C sensor app. That is the reliable signal iOS gives userland.

---

## Requirements

1. **Jailbroken** iPhone 7 Plus (or similar arm64 device) on a supported iOS for your jailbreak.  
   Without jailbreak, iOS will **not** load a custom dylib into every app.
2. **MobileSubstrate / Substitute / ElleKit** (usual Theos tweak stack).
3. **Theos** to compile from source (macOS or Linux with iOS toolchain).

This repository is **source**. You (or GitHub Actions + Theos) build the `.deb` / dylib.

---

## Project layout

```
Pip/
├── Makefile
├── control
├── Pip.plist                 # injection filter (UIKit)
├── Sources/
│   ├── Tweak.xm              # hooks (FPS, scale, blur, animations)
│   ├── PipHUD.h / PipHUD.m   # floating pill + panel
│   ├── PipStats.h / PipStats.m
│   └── PipPrefs.h / PipPrefs.m
├── layout/Library/PreferenceLoader/Preferences/Pip.plist
└── .github/workflows/build.yml
```

**Main tweak entry:** `Sources/Tweak.xm`  
**HUD Objective-C:** `Sources/PipHUD.m`  
**Prefs domain:** `com.pip.cool`

---

## Build (local)

```bash
# Install Theos first: https://theos.dev
export THEOS=~/theos
cd Pip
make package
# Install to device:
make install
```

After install, **respring**. Open Settings → **Pip** (PreferenceLoader) to tune FPS / graphics.

Default prefs file path:

`/var/mobile/Library/Preferences/com.pip.cool.plist`

---

## GitHub

Suggested repo name: **`Pip`** or **`pip-cool-tweak`**.

Workflow: [`.github/workflows/build.yml`](.github/workflows/build.yml) — checks out, sets up Theos, runs `make package`, uploads `.deb` artifact.

> The Actions runner must successfully install Theos SDKs. If the workflow warns “No packages/”, fix SDK install on the runner; the Makefile itself is standard Theos.

---

## Honest limits (please read)

- **No 120 Hz** on iPhone 7 Plus — the display is 60 Hz.
- **No 100% heat removal** — silicon always produces heat when it works. Pip only makes it work *less*.
- **Heavy 3D games** often bypass UIKit paths; FPS/scale hooks help less there than in normal apps.
- If the phone already hits **thermal critical** and freezes, also: free storage, replace a swollen battery if needed, remove case while charging, avoid direct sun, update only as far as your jailbreak allows.
- Pip is a **gift of care** for an old phone — not a miracle chip upgrade.

---

## License

MIT — use it, fork it, keep your 7 Plus alive a little longer.
