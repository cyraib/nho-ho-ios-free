# Nhớ Hộ — iOS personal development

Native iPhone host for the Nhớ Hộ calendar and photo journal web app.

## Build from Windows

Open **Actions → iOS free development IPA → Run workflow**. Leave `app_origin` empty to enter the deployed HTTPS app origin on the iPhone. Download `NhoHo-Free-unsigned` after success. The IPA is unsigned and must be signed/installed locally using AltStore Classic and your own Apple Account.

See [Windows + iPhone setup](ios/WINDOWS-FREE.md). Free provisioning requires periodic refresh. This is not an App Store or TestFlight release.

## Scope

The free target excludes App Groups, home-screen widget extensions and native push. It loads an existing HTTPS web deployment; web/backend sources and credentials are not in this repository. Camera, backup transfer and signing still require device verification. Never upload Apple passwords, signing credentials, diary data or server secrets.
