# macOS MDM Scripts

Here you will find Mac-specific installation scripts and procedures for use with popular MDM solutions, including Kandji, Jamf, and others.

## The 'Evergreen' Installer

The "Evergreen" installer is responsible for always keeping devices updated with the latest version of the Mondoo tools. By using the install.mondoo.com API, it looks for the latest version of the Mondoo Mac package and compares it to the installed version, if they differ, it upgrades. It also inserts an embedded local configuration file using a non-default file location so that other installations of Mondoo do not conflict with this installation.

Please note that you must upgrade the script with your Mondoo configuration before deploying it.

This is the installer Mondoo uses to continuously scan its employee workstations.

### Kandji

To deploy Evergreen on Kandji, follow these steps:

1. Obtain your Mondoo configuration file or create a new one and embed it into the ___evergreen.sh___ script.  To create a config, log into the [Mondoo Console](https://console.mondoo.com), navigate to your space, select **Settings**, go to the **Service Accounts** tab, and select the plus symbol (+) button.
2. Log in to Kandji and navigate to **Library**.
3. Select the 'Add New' button, select 'Custom Scripts', and then select 'Add & Configure'
4. Name it 'Mondoo Evergreen Installer' and select the appropriate Blueprint(s) to add it to. Set the 'Execution Frequency' to 'Run daily'. Do not enable Self Service.
5. Copy and paste the ___evergreen.sh___  script contents into the script box.
6. Select 'Save'. Done!

Once set up in the library, you can visit the library items 'Status' tab to see the per device installation progress.
