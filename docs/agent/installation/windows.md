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


## Windows Subsystem for Linux (WSL)

If you are using the WSL, you can use our [Bash installer for Linux](./bash):

```
curl -sSL https://mondoo.io/download.sh | bash
MONDOO_REGISTRATION_TOKEN='ey...ax'
mondoo register --token $MONDOO_REGISTRATION_TOKEN
```

![Install Mondoo on Windows Subsystem for Linux (WSL)](../assets/windows_wsl_mondoo_install.png)

## MSI Installer

Mondoo ships with a Windows services that runs in the background. The Windows service expects the mondoo configuration to be located in `C:\ProgramData\Mondoo\mondoo.yml`. After the installation, the mondoo CLI is enabled in the system path by default.

**Desktop Experience (GUI) Installation:**

 * Download the [mondoo agent](https://releases.mondoo.io/mondoo/)
 * Execute the installer as administrator
 * Follow the steps, agree to the license agreement, and register the agent with your Mondoo Acount

If you enter a registration token during the installation, the agent will be registered automatically. Be aware that the Windows service is not activated automatically. If you skip the registration in the GUI installer, use the manual regisstration processs described below.

**Console Installation:**

If you want to roll-out the mondoo agent, you'd like to install the agent via a script. Mondoo can be installed via cmd or Powershell: 

```powershell
# Run with Powershell
Start-Process -Wait msiexec -ArgumentList '/qn /i mondoo.msi'

# Run with Cmd
start /wait msiexec /qn /i mondoo.msi REGISTRATIONTOKEN="token"
```

The `REGISTRATIONTOKEN` allows you to pass in the token and the MSI installer will run the registration as part of the installation step. Otherwise use the registration method described below.

**Manual registration and auto enabling Mondoo service**

The MSI installer registered the `mondoo` binary into the system path. The registered Windows services expect the configuration to be located at `C:\ProgramData\Mondoo\mondoo.yml`
 
```
mondoo register --config C:\ProgramData\Mondoo\mondoo.yml --token 'eyJh....tpZC'
```

Once the registration is completed, you can enable the service in Powershell via:

```powerhshell
Set-Service -Name 'Mondoo' -StartupType Automatic
```

List the Mondoo service details in Powershell: 

```powerhshell
Get-Service Mondoo | Select-Object -Property Name, StartType, Status
```

**Debugging**

Msi ships with built-in debug logging. Use the `/L*vx debug.log` flag to log into the debug.log file during the installaation:

```powershell
# Run with Powershell
Start-Process -Wait msiexec -ArgumentList '/i mondoo.msi /L*vx debug.log'

# Run with Cmd
msiexec /i mondoo.msi /L*vx debug.log
```