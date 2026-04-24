# Arch Linux AUR PKGBUILD for Mondoo

This directory contains the PKGBUILD generator for the Arch Linux AUR system. Use is simple:

1. Ensure Go, Make & Git are installed
2. Run ```make update```, this will create mql and cnspec directories with the appropriate files
3. Push those generated files to the appropriate AUR Git repository, such as: https://aur.archlinux.org/mql
4. Go to the AUR website to verify the package (it can take some time for the web pages to regenerate), eg: https://aur.archlinux.org/packages/mql

## Install mql & cnspec

The packages are published on [AUR](https://aur.archlinux.org):

- [mql](https://aur.archlinux.org/packages/mql)
- [cnspec](https://aur.archlinux.org/packages/cnspec)

### Installation with MakePKG

```bash
# Install mql
git clone https://aur.archlinux.org/mql
 cd mql
 makepkg -si

# Install cnspec (requires mql to be installed)
git clone https://aur.archlinux.org/cnspec
 cd cnspec
 makepkg -si
```

### Installation with Yay

We highly recommend using one of the [AUR_helpers](https://wiki.archlinux.org/title/AUR_helpers) like [`yay`](https://github.com/Jguer/yay/) to install the packages. Note that mql is a dependency of cnspec, so Yay will automatically install it for you.

```bash
# install mql
yay -Ss mql

# install cnspec
yay -Ss cnspec
```

# Test github action

- create the `.secret` file with the following content:

```
AUR_USERNAME="Patrick Münch"
AUR_EMAIL="patrick@mondoo.com"
AUR_SSH_PRIVATE_KEY="-----BEGIN OPENSSH PRIVATE KEY-----\n....\n-----END OPENSSH PRIVATE KEY-----\n"
```

- create the `sample-event.json` file with the following content:

```
{
  "action": "workflow_dispatch",
  "inputs": {
      "version": "6.13.1"
  }
}
```

- run the following command:

```bash
act -j aur-publish --secret-file .secrets --eventpath sample-event.json -v
```
