# Code signing policy — WEmulDroid

**Status: application not submitted; unsigned development builds only.** No WEmulDroid release is presently signed by SignPath Foundation. A certificate is neither granted nor configured.

If WEmulDroid is admitted to the program, the intended credit is: **Free code signing provided by SignPath.io, certificate by SignPath Foundation**.

## Project and release scope

- Source of truth: https://github.com/pilialvu75-hue/WEmulDroid
- Official release page: https://github.com/pilialvu75-hue/WEmulDroid/releases
- License: MIT, as stated in [LICENSE](../LICENSE).
- WEmulDroid is a Windows desktop manager for the official Android Emulator. It does not bundle or sign Google Play, Android system images, SDK tools or third-party application packages. Those components are obtained separately with user approval from the respective suppliers.
- Only WEmulDroid's own source-built launcher, first-party runtime PowerShell scripts, Windows installer and uninstall component are candidates for a future project signature.
- No pre-existing release will be retroactively described as signed. Signed releases must have a new, immutable release tag and must match reviewed source and build artifacts.

## Publisher and verification

On acceptance, the intended Authenticode publisher will be **SignPath Foundation**, not the project owner. Until the first successful signed release, users should assume beta EXEs are unsigned and may be blocked by Windows security policy. The project's SHA-256 file protects against mismatch with the published release but is **not** a trusted code-signing signature.

For a future signed release, use Windows Explorer > Properties > Digital Signatures to inspect the publisher, and check the release source tag and checksum. The release must never instruct users to turn off Smart App Control or install a custom trusted root certificate.

## Roles and approval

- **Committer / project maintainer:** the repository owner, [pilialvu75-hue](https://github.com/pilialvu75-hue). GitHub repository permissions are the authoritative membership list.
- **Reviewer:** the repository owner must review external contributions before merging them. Any additional reviewers must be explicitly approved and listed before signing activation.
- **Signing approver:** the repository owner, subject to SignPath's acceptance and enrollment. Every release signing request requires manual approval; there is no automatic approval on CI success.
- **Access verification still pending:** the account owner must confirm multi-factor authentication for GitHub and SignPath and satisfy the provider's release provenance conditions. This document does not claim MFA or enrollment is complete.

All edits to build and signing workflows should be reviewed with particular care. Signatures cannot be granted for binaries of third-party upstream projects under WEmulDroid's project identity.

## Privacy, network and system changes

WEmulDroid does not send local diagnostics or Android logs to a remote server automatically. User-driven actions can contact:
- GitHub Releases for update discovery and downloads;
- official Google/Android sources to download SDK tools, images or services, after consent;
- user-provided HTTPS URLs when the user explicitly requests downloading an APK.

The Google Play / Android services operate inside Android and have their own privacy notices. Account logins occur within the Android emulator, not the WEmulDroid updater. Diagnostic bundles remain on the local computer unless the user chooses to share them. Users should review reports because logs and screenshots may include personal data.

The installer creates per-user program files, application shortcuts and an uninstaller. It does not change Windows security settings and is not supposed to delete persistent Android SDK, AVD or Play Store data. Uninstall through Windows Settings > Installed Apps or the WEmulDroid uninstall entry. The installed program and user-owned Android environment are intentionally separate.

## Controlled release process (intended, not yet active)

1. Review source, license obligations and all files included in the installer.
2. Build from a pinned GitHub commit/tag through an approved hosted workflow; do not submit local replacement artifacts.
3. Verify build provenance and the identity of the project repository.
4. Obtain explicit SignPath approval for each signing request.
5. Sign only eligible first-party binaries and package them in the approved order, ensuring the signed installer and uninstaller can be verified.
6. Require valid Authenticode signatures and consistent publisher identity across installer, launcher and scripts. Publish checksums and release notes.
7. Validate the complete install/update on a Windows 11 test PC with Smart App Control enabled; CI success alone is insufficient.
8. Preserve SDK, AVD, installed APKs, Google Play login and local reports.

## Disclosure and incident response

Security questions and suspected malicious releases may be reported via [GitHub Issues](https://github.com/pilialvu75-hue/WEmulDroid/issues). Do not disclose passwords, secrets, private keys, personal Android logs or authentication data in a public issue. A suspected compromised release must stop further signing and distribution until investigated.

See [code-signing options](CODE_SIGNING_OPTIONS.md) and [installer architecture](INSTALLER_ARCHITECTURE.md). Official provider conditions: https://signpath.org/terms.html .
