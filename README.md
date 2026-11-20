# Eden Launcher

Windows desktop launcher for [Eden](https://github.com/CJ-SPT/Eden), written in C# and Avalonia.

The launcher prepares an isolated build 3662168 client, creates standard or invitation-protected developer accounts, signs in, optionally remembers accounts, and launches against local or remote servers. The layout follows the EVE launcher: navigation rail, reserved news column, account cards, game panel, and connection status. Server news delivery is intentionally deferred.

The account header contains **Add account**. Compact cards highlight the selected account, with **Sign out** below the list and launch-group controls together underneath. The wider game panel shows the selected account and running-client count above the full-width **Play** button. Client preparation remains in **Client settings**; the extra preparation shortcut appears only while setup is needed.

## Native chat

For updated Eden servers, Play automatically adds the server’s public chat certificate to the prepared client copy’s certifi bundle. The server signs the matching certificate-bundle hash while keeping every other client file pinned. Existing public roots are preserved and repeated launches are idempotent. This enables native TLS chat on TCP 5222 without modifying the source EVE installation, installing an OS trust root or disabling TLS. When switching to a server that omits the optional certificate field, Play restores the exact pinned original bundle, including clients modified by earlier launchers. Unrecognized bundle edits are rejected before changing files. The server and launcher both need their chat updates rebuilt.

## Run

Extract the Windows x64 release ZIP and open `Eden.Desktop.exe`. No separate .NET installation is required for the published build.

1. Open **Settings**, enter the Eden launcher API address, and choose **Connect**. The local default is `http://127.0.0.1:26002`. For a
   remote server with a private CA, select its CA certificate with **Browse…**, or choose **Download CA** and verify the fingerprint
   provided by the server operator.
2. Select a prepared Eden client containing `tq` and `ResFiles`, then choose **Use this client**. Alternatively, expand **Prepare a new Eden client**, choose the pinned source and an empty destination, and prepare the copy. Other EVE builds are rejected.
3. Choose **Add account** and sign in or create an account with a 6–128 character password. **Remember me on this computer** is
   selected by default. Clear it for a temporary sign-in on a shared computer. Developer accounts require the server operator's invitation code.
4. Choose the account card and press **Play**. Create characters in the game. Closing the launcher window while games run keeps their gateway connections alive in the system tray. Exit after closing the games.

The server runs separately. See [server setup](docs/server-setup.md) and [acceptance results](docs/acceptance.md).

Remembered sign-ins work across server restarts that preserve the world save. If you opened the launcher while the server was
offline, choose **Connect** when it returns. **Play** and **Launch group** can renew a rejected access token using the remembered
sign-in. If your saved sign-in has expired or you changed the server address, sign in again to save a new one.

## Launch groups

Servers select mod sets authored with Eden Modding SDK. Play and launch groups check the required set and install its
verified client archive and signed manifest before starting the game. The launcher supports server API versions 1
and 2, including legacy skill packages. It retains the pinned original, recovers interrupted updates, and restores
original files when switching to an unmodified server. Close games sharing an installation before changing its
package. Update the launcher with the server; older launchers reject version-2 servers.

In the account column, under **Launch groups**, choose **New group**, give it a name, select its accounts, and save. Choose the saved group and press **Launch group** to start its accounts one after another using the current server profile's verified client. Use **Edit** to rename the group or change its members; **Delete** removes only the group.

Groups are saved separately for each server profile. Add and sign in to each account first; enable **Remember me** to keep group launching available after restarting the launcher. Active sign-ins also work without Remember me during the current launcher session. Groups never store passwords or tokens.

Already-running accounts are skipped. Each account gets its own launch ticket and client settings. An account that needs sign-in or fails to start is listed below the group controls while the other accounts continue. Sign in to any accounts that need attention, then launch the group again; clients already running will be skipped. **Cancel** stops pending launches and leaves clients already started open. The selected account and the individual **Play** button continue to work independently.

## Build and verify

Install SDK **10.0.403** and Python 3.11 or newer. From this repository:

```powershell
dotnet tool restore
dotnet restore
dotnet build --no-restore
dotnet test --no-build
.\tools\Format.ps1 -Check
```

Apply formatting with `.\tools\Format.ps1`. CSharpier 1.3.0 owns layout; never run full `dotnet format`.

```powershell
.\tools\Publish.ps1
```

This creates `artifacts/Eden-Launcher-win-x64.zip` and the standalone
`artifacts/publish/win-x64/Eden.Desktop.exe`. The Windows x64 publish is self-contained
and bundles .NET and native dependencies into the EXE; some native components are
extracted to a temporary directory on first launch.

## Windows 11 CI/CD

The [Windows 11 x64 workflow](.github/workflows/windows11-x64.yml) runs on a hosted
Windows build runner for every pull request to `main`, push to `main`, and manual
workflow dispatch. It installs the SDK pinned in `global.json`, restores tools and
packages, builds the solution, runs the automated test suite, checks formatting,
publishes the EXE and validates its Windows x64 executable header.

After a successful run, select **Actions → Build Windows 11 x64 → the workflow run → Artifacts**
to download either `Eden-Launcher-win-x64-exe` or `Eden-Launcher-win-x64-zip`.
GitHub Actions artifact downloads themselves arrive as ZIPs. Extract them and
launch `Eden.Desktop.exe` on 64-bit Windows 11. The portable distribution
also includes this README and the `docs` directory.

After merging to `main`, pushing a version tag such as `v1.0.0` triggers
the same verification and automatically creates a GitHub Release with both
`Eden.Desktop.exe` and `Eden-Launcher-win-x64.zip` as downloadable assets.
No release is created for pull requests or ordinary branch pushes.

The executable is **unsigned** until a code-signing certificate and signing
process are configured; Windows SmartScreen may warn when it is downloaded.
CI verifies compilation, tests and the PE architecture, not a full interactive
login and game-launch session on Windows 11.

## Structure

- `Eden.Launcher`: Avalonia views, MVVM, native folder pickers, tray integration and Windows credential protection.
- `Eden.Launcher.Core`: typed HTTP contracts, settings, build validation, cancellable preparation, manifest verification, launch tracking and TLS gateway relay.
- `Eden.Launcher.Tests`: core and Avalonia headless tests.

The launcher talks only to the versioned HTTP API. It does not access the server database or load server assemblies. Settings and encrypted remembered tokens live under `%LOCALAPPDATA%\Eden Launcher`. Passwords are never saved. Set `EDEN_LAUNCHER_PROFILE_DIRECTORY` to use an isolated profile directory.

Client downloads, automatic updates, server process management, email and password recovery are outside v1. The news column is reserved for a future server news feed. It contains no hard-coded posts or external news requests.

## Artwork

The launcher uses the blue outbound-arrow icon from the coordinated Eden application family for the
executable, window, system tray and navigation rail. Editable SVG, 1024-pixel PNG and multi-size ICO assets
are included in `src/Eden.Launcher/Assets/eden-launcher.*`. The canonical sources and export instructions are
in [Eden application icons](https://github.com/CJ-SPT/Eden/tree/main/assets/icons). These original vector
icons are covered by the repository's MIT license.

The background and capsuleer panel use original, unmodified EVE Online images published on [the official EVE website](https://www.eveonline.com/). URLs and SHA-256 checksums are recorded in `Assets/sources.json` in the desktop project. EVE Online artwork remains the property of CCP Games and its rights holders. Eden is an independent project. No generated artwork is included.

Icon automated validation (November 9, 2026): SVG/PNG/ICO exports and copy equality passed; Windows extracted
the embedded executable icon. Tool/solution restore, isolated zero-warning build (4.22 seconds) and formatting passed.
The exact `GroupLaunchTests.GroupControlsBindToCommandsAndRequireConnectionAndVerifiedClient` case passed,
followed by `FullyQualifiedName~Eden.Launcher.Tests.GroupLaunchTests|FullyQualifiedName~Eden.Launcher.Tests.ViewModelTests`
(27 passed, 771-millisecond runner duration). The initial normal-output build was blocked by the running
launcher; successful validation used `--artifacts-path artifacts/icon-validation`. The full suite was not run.

Icon live acceptance: Not performed; agent client testing is disabled.

Icon optional maintainer checks: inspect the rebuilt executable, taskbar, tray and navigation icon at your display scaling.

## Mod-set cutover validation — November 9, 2026

Automated validation: tool/solution restore and zero-warning build passed. The focused filter selected
SkillPackageTests, ViewModelTests, GroupLaunchTests, ApiAndLaunchTests, ChatManifestTests and InstallationTests:
62 tests passed without skips, with a one-second runner duration and 4.83-second build. Formatting verification
passed. Coverage includes API versions 1/2, exact ModSetId requests, authenticated downloads, archive verification,
installation recovery/restoration and individual/group launch behavior. This was an affected-test run.

Live acceptance: Not performed; agent client testing is disabled.

Optional maintainer checks: launch the example mod on the matching updated server and inspect its native window.
