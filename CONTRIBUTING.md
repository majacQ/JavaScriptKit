# Contributing to JavaScriptKit

Thank you for considering contributing to JavaScriptKit! We welcome contributions of all kinds and value your time and effort.

## Getting Started

### Reporting Issues
- If you find a bug, have a feature request, or need help, please [open an issue](https://github.com/swiftwasm/JavaScriptKit/issues).
- Provide as much detail as possible:
  - Steps to reproduce the issue
  - Expected vs. actual behavior
  - Relevant error messages or logs

### Setting Up the Development Environment
1. Clone the repository:
   ```bash
   git clone https://github.com/swiftwasm/JavaScriptKit.git
   cd JavaScriptKit
   ```

2. Install **OSS** Swift toolchain (not the one from Xcode):
    <details>
    <summary>For macOS users</summary>

    ```bash
    (
        SWIFT_TOOLCHAIN_CHANNEL=swift-6.0.2-release;
        SWIFT_TOOLCHAIN_TAG="swift-6.0.2-RELEASE";
        SWIFT_SDK_TAG="swift-wasm-6.0.2-RELEASE";
        pkg="$(mktemp -d)/InstallMe.pkg"; set -ex;
        curl -o "$pkg" "https://download.swift.org/$SWIFT_TOOLCHAIN_CHANNEL/xcode/$SWIFT_TOOLCHAIN_TAG/$SWIFT_TOOLCHAIN_TAG-osx.pkg";
        installer -pkg "$pkg" -target CurrentUserHomeDirectory;
        export TOOLCHAINS="$(plutil -extract CFBundleIdentifier raw ~/Library/Developer/Toolchains/$SWIFT_TOOLCHAIN_TAG.xctoolchain/Info.plist)";
        swift sdk install "https://github.com/swiftwasm/swift/releases/download/$SWIFT_SDK_TAG/$SWIFT_SDK_TAG-wasm32-unknown-wasi.artifactbundle.zip";
    )
    ```

    </details>

    <details>
    <summary>For Linux users</summary>
    Install Swift 6.0.2 by following the instructions on the <a href="https://www.swift.org/install/linux/tarball/">official Swift website</a>.

    ```bash
    (
        SWIFT_SDK_TAG="swift-wasm-6.0.2-RELEASE";
        swift sdk install "https://github.com/swiftwasm/swift/releases/download/$SWIFT_SDK_TAG/$SWIFT_SDK_TAG-wasm32-unknown-wasi.artifactbundle.zip";
    )
    ```

    </details>

3. Install dependencies:
   ```bash
   make bootstrap
   ```

### Running Tests
- Run unit tests:
  ```bash
  make unittest SWIFT_SDK_ID=wasm32-unknown-wasi
  ```
- Run integration tests:
  ```bash
  make test SWIFT_SDK_ID=wasm32-unknown-wasi
  ```

### Editing `./Runtime` directory

The `./Runtime` directory contains the JavaScript runtime that interacts with the JavaScript environment and Swift code.
The runtime is written in TypeScript and is checked into the repository as compiled JavaScript files.
To make changes to the runtime, you need to edit the TypeScript files and regenerate the JavaScript files by running:

```bash
make regenerate_swiftpm_resources
```

## Support
If you have any questions or need assistance, feel free to reach out via [GitHub Issues](https://github.com/swiftwasm/JavaScriptKit/issues) or [Discord](https://discord.gg/ashJW8T8yp).