# Mondoo PKG Builder

A package builder for Mondoo, initially based on [KosalaHerath/macos-installer-builder](https://github.com/KosalaHerath/macos-installer-builder)

![Mondoo PKG Installer](mondoo-pkg.png)

## Package Build from Mondoo Releases
Using the *build-pkg.sh* script, you can build a package locally from tarballs on releases.mondoo.com!  Just give the script a Mondoo version and it will download both ARM and AMD64 tarballs, extract them and build them into a universal binary and then create a PKG.

```bash
$ ./build-pkg.sh 5.8.0
Downloading Release 5.8.0
Downloading AMD64 Binary Release...
Downloading ARM64 Binary Release...
Creating Universal Binary....
Building Package....
                                   ___           _        _ _
 _ __ ___   __ _  ___ ___  ___    |_ _|_ __  ___| |_ __ _| | | ___ _ __
| '_ ` _ \ / _` |/ __/ _ \/ __|    | || '_ \/ __| __/ _` | | |/ _ \ '__|
| | | | | | (_| | (_| (_) \__ \    | || | | \__ \ || (_| | | |  __/ |
|_|_|_| |_|\__,_|\___\___/|___/   |___|_| |_|___/\__\__,_|_|_|\___|_|

                 ____        _ _     _
                | __ ) _   _(_) | __| | ___ _ __
                |  _ \| | | | | |/ _` |/ _ \ '__|
                | |_) | |_| | | | (_| |  __/ |
                |____/ \__,_|_|_|\__,_|\___|_|

Application Name : Mondoo
Application Version : 5.8.0
[2021-10-08 01:27:28][WARN] Apache Maven was not found. Please install Maven first.
[2021-10-08 01:27:28][WARN] Ballerina was not found. Please install ballerina first.
[2021-10-08 01:27:28][INFO] Installer generating process started.
[2021-10-08 01:27:28][INFO] Cleaning /Users/benr/mondoo_pkg/macos-installer-builder/macOS-x64/target directory.
[2021-10-08 01:27:28][INFO] Application installer generation process started.(3 Steps)
[2021-10-08 01:27:28][INFO] Apllication installer package building started.(1/3)
[2021-10-08 01:27:28][INFO] Application installer product building started.(2/3)
[2021-10-08 01:27:28][INFO] Application installer generation steps finished.
[2021-10-08 01:27:28][INFO] Installer generating process finished
SUCCESS! Your package is ready to rock, hot and fresh: Mondoo-macos-universal-5.8.0.pkg
Cleaning up.  Good bye.
```

## Non-Interactive PKG Installation

From the OSX Terminal:

```bash
$ sudo installer -pkg Mondoo-macos-universal-5.8.0.pkg -target /Applications
installer: Package name is Mondoo
installer: Upgrading at base path /
installer: The upgrade was successful.
$ /usr/local/bin/mondoo version
Mondoo 5.8.0 (5a8c079a, 2021-10-06T15:27:22Z)
```

For debugging, add the *-dumplog /path/to/some-file.log* flag to *installer*.

## Creating Universal (AMD64 & ARM64) Binaries

First, compile your app for both platforms, seperately: 

```bash
$ GOOS=darwin GOARCH=amd64 go build -o hello_amd64 hello.go 
$ GOOS=darwin GOARCH=arm64 go build -o hello_arm64 hello.go
```

Then use the Xcode tool *lipo* to combine them into a single universal binary:

```bash
$ curl -Os https://releases.mondoo.com/mondoo/5.8.0/mondoo_5.8.0_darwin_amd64.tar.gz
$ curl -Os https://releases.mondoo.com/mondoo/5.8.0/mondoo_5.8.0_darwin_arm64.tar.gz
$ tar xfvz mondoo_5.8.0_darwin_amd64.tar.gz
x mondoo
$ mv mondoo mondoo-amd64
$ tar xfvz mondoo_5.8.0_darwin_arm64.tar.gz
x mondoo
$ mv mondoo mondoo-arm64

$ file mondoo-a*
mondoo-amd64: Mach-O 64-bit executable x86_64
mondoo-arm64: Mach-O 64-bit executable arm64
$ lipo -create -output mondoo mondoo-amd64 mondoo-arm64
$ file mondoo
mondoo: Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64]
mondoo (for architecture x86_64):	Mach-O 64-bit executable x86_64
mondoo (for architecture arm64):	Mach-O 64-bit executable arm64
```

Now test it, just in case:

```bash
$ ./mondoo version
Mondoo 5.8.0 (5a8c079a, 2021-10-06T15:27:22Z)
```

*Warning* The binary will be twice as large, weighing in at 370M for 5.8.0.  By contrast, the Linux binary is only 36M.

## Creating a PKG


Update the binaries in macOS-x64/application/bin/, then create the PKG:

```bash
## Be sure to capitalize Mondoo
bash macOS-x64/build-macos-x64.sh Mondoo 5.8.0
```

You will find the produced PKG here: ***macOS-x64/target/pkg/Mondoo-macos-x64-5.8.0.pkg***

## Uninstalling

An uninstaller is provided in the installation directory: 

```bash
$ sudo /Library/mondoo/5.8.0/uninstall.sh
```

## Package Naming

Considering the names of other packages out there:

* Slack-4.22.0-macOS.dmg
* terraform_1.0.11_darwin_arm64.zip
* VSCode-darwin-universal.zip
* go1.17.3.darwin-amd64.pkg

Ultimate, it appears "darwin" is still in common usage and the Hashicorp naming is a good middle ground (plus we already use it and no other format is objectively better), therefore we'll use the naming scheme: mondoo_1.2.3_darwin_universal.pkg

# Signing and Notarization

This repository requires several Github Action Secrets to sign and notarize:

- APPLE_KEYS_PASSWORD: Cleartext password to decrypt the p12 file's (same pass used on both!)
- APPLE_KEYS_CODESIGN: base64 encoded p12 for Developer\ ID\ Application-\ Mondoo\,\ Inc.\ \(W2KUBWKG84\)
- APPLE_KEYS_CODESIGN_ID: Cleartext ID: "Developer ID Application: Mondoo, Inc. (W2KUBWKG84)" 
- APPLE_KEYS_PRODUCTSIGN: base64 encoded p12 for Developer\ ID\ Installer-\ Mondoo\,\ Inc.\ \(W2KUBWKG84\)
- APPLE_KEYS_PRODUCTSIGN_ID: Cleartext ID: "Developer ID Installer: Mondoo, Inc. (W2KUBWKG84)"
- APPLE_ACCOUNT_USERNAME: The AppleID username for access to the Notarization service ("apple-builder@mondoo.io")
- APPLE_ACCOUNT_PASSWORD: The "App Specific Password" for use when Notorizing Mac packages, to rotate this password login to appleid.apple.com/account as the above user (login credentials are in BitWarden, in the "Apple ID: Notorizing Account" item)

The Certificates & P12's can be found in Google Drive.  Refer to our internal documentation in [Notion: Apple Developer Network](https://www.notion.so/mondoo/Apple-15b14791a0f54609978a5e52fd8e6cfb#562019a837bf450e89dd3d7926f279ab).