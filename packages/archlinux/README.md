# Arch Linux AUR PKGBUILD for Mondoo

This repository holds the PKGBUILD generator and the PKGBUILD files from [https://aur.archlinux.org/packages/mondoo/](https://aur.archlinux.org/packages/mondoo/)


## Install cnquery & cnspec

The packages are published on [AUR](https://aur.archlinux.org):

- [cnquery](https://aur.archlinux.org/packages/cnquery)
- [cnspec](https://aur.archlinux.org/packages/cnspec)

### Installation with MakePKG

```bash
# Install cnquery
git clone https://aur.archlinux.org/cnquery 
 cd cnquery 
 makepkg -si
 
# Install cnsepc (requires cnquery to be installed)
git clone https://aur.archlinux.org/cnspec 
 cd cnspec
 makepkg -si
```

### Installation with Yay

We highly recommend using one of the [AUR_helpers](https://wiki.archlinux.org/title/AUR_helpers) like [`yay`](https://github.com/Jguer/yay/) to install the packages.  Note that cnquery is a dependancy of cnspec, so Yay will automatically install it for you.

```
# install cnquery
yay -Ss cnquery

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
