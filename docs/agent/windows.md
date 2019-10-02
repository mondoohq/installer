# Installing Mondoo Agent on Windows workstation

## Powershell

Run this powershell script to install Mondoo to its default location in `C:\Users\<user>\mondoo`.

```bash
# For older Windows versions we may need to activate newer TLS config to prevent
# "Invoke-WebRequest : The request was aborted: Could not create SSL/TLS secure channel."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download mondoo binary
iex (new-object net.webclient).downloadstring('https://mondoo.io/download.ps1')
```

![Install Mondoo on Windows](../assets/windows_mondoo_install.png)

Once the agent is downloaded, you can register the agent
```bash
$MONDOO_REGISTRATION_TOKEN="pastetokenhere"
mondoo register --token $MONDOO_REGISTRATION_TOKEN
  ✔  agent //agents.api.mondoo.app/spaces/peaceful-burnell-555533/agents/1ON7UPoNpkKxkMncKTFUcwZLVrt registered successfully
```

## Binary Download

Mondoo distributes binaries for Windows. To install agent, download the [appropriate package](https://releases.mondoo.io/mondoo/). Archives for Windows systems use `.zip`. After the download is complete, extract the content. The Mondoo agent is a single binary named `mondoo`. The last step is to add the `mondoo` binary to the path. You can configure the path via the control panel:

1. Go to `Control Panel` -> `System` -> `System settings` -> `Environment Variables`
2. In section `System variables` scroll down until you find `Path`.
3. Click edit and add the new path, make sure you split paths vis semicolon i.e. `C:\path1;C:\path2`
5. Launch a new console to take changes in effects


## WSL: Windows Subsystem for Linux

If you are using the WSL, you can use our [Bash installer for Linux](./bash):

```
curl -sSL https://mondoo.io/download.sh | bash
MONDOO_REGISTRATION_TOKEN='ey...ax'
mondoo register --token $MONDOO_REGISTRATION_TOKEN
```


![Install Mondoo on Windows Subsystem for Linux (WSL)](../assets/windows_wsl_mondoo_install.png)