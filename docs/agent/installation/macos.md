# Installing Mondoo Agent on macOS workstation

![Installing Mondoo Agent on macOS workstation](../../assets/videos/mondoo-setup-macos.gif)

At first, add mondoo brew tap:

```
brew tap mondoolabs/mondoo
```

Then, install the mondoo agent:

```bash
brew install mondoo
```

Register the agent with your mondoo cloud organization

```bash
mondoo register --token 'PASTE_MONDOO_REGISTRATION_TOKEN'
```
