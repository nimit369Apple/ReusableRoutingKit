# ReusableRoutingKit

Binary Swift Package for iOS 15+, distributed without original Swift implementation files.

## Install

Add `https://github.com/nimit369Apple/ReusableRoutingKit` in Xcode's
**File > Add Package Dependencies**, and choose version `1.0.0`.

Then use `import ReusableRoutingKit` in your application.

The package also resolves the upstream public `BrowserKit` dependency. Because the
compiled framework links BrowserKit as part of its build, test integration carefully
if your app directly includes BrowserKit as well. Binary frameworks may need
updates when new Xcode/Swift versions become available.

## Release

Binary artifact: [ReusableRoutingKit-1.0.0.xcframework.zip](https://github.com/nimit369Apple/ReusableRoutingKit/releases/download/1.0.0/ReusableRoutingKit-1.0.0.xcframework.zip)  
Checksum: `767d977e510cf414b4b548252a4d88ce873d065549e332a1e124d5957ab290c4`

The public Swift interfaces are visible to users of the framework; compiled code
is not the same as cryptographic source secrecy.

See the existing repository license and publication history for licensing of
previously public source releases. Moving to binary distribution does not revoke
previously granted licenses.
