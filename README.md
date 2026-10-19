# ReusableRoutingKit — Binary Swift Package

This package ships **two different dynamic XCFrameworks**:

- `ReusableRoutingKit`: Your original, unmodified routing/browser code.
- `BrowserKit`: The separate dynamically linked BrowserKit module it uses.

Original private ReusableRoutingKit sources are not in this public repository.

## Install

Add `https://github.com/nimit369Apple/ReusableRoutingKit` in Xcode, choose `1.0.3` or later compatible versions, and add **ReusableRoutingKit** to your app target. Use `import ReusableRoutingKit` in Swift files.

Xcode must link and embed/sign `BrowserKit.framework` (the dependency) exactly once at runtime. Check your app target's **Frameworks, Libraries, and Embedded Content**, and test both a simulator and physical device. If your app or another dependency already links the **upstream source BrowserKit**, remove the overlapping source dependency before using the binary BrowserKit, since two modules defining `BrowserKit` classes can still conflict.

## Release downloads

- [ReusableRoutingKit-1.0.3.xcframework.zip](https://github.com/nimit369Apple/ReusableRoutingKit/releases/download/1.0.3/ReusableRoutingKit-1.0.3.xcframework.zip) — `111dbe4407290fe8b0d4417a15d0553895feb6abf986fc805190d60e16a80f06`
- [BrowserKit-1.0.3.xcframework.zip](https://github.com/nimit369Apple/ReusableRoutingKit/releases/download/1.0.3/BrowserKit-1.0.3.xcframework.zip) — `14ef546873a15fb33e4974e4e266c80595f92efd7d07bbc159c9c0e206464c69`

**Both** assets must be uploaded to the GitHub Release with tag `1.0.3`. The tag must point to the commit with this generated Package.swift. Both binaries must be built from the **same** build invocation; never reuse the old statically-linked `ReusableRoutingKit 1.0.1` binary.

## BrowserKit license / attribution

This release incorporates compiled BrowserKit code originally from https://github.com/markbattistella/BrowserKit, at pinned commit `bbfce56eea73771a74fc8c0431632de4d5e4b6f3`. Its MIT license is preserved under `THIRD_PARTY_NOTICES/BrowserKit-LICENSE`.

Moving future releases to binary distribution does not erase copies of previously public source or existing MIT license grants. Public Swift interfaces remain visible and binaries may be reverse engineered.
