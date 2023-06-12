# MacOS MDM Scripts

Here you will find Mac specific installation scripts and proceedures for use with popular MDM solutions, including Kandji, JAMF, and others.

## The 'Evergreen' Installer

The so-called 'Evergreen' installer is responsible for always keeping devices updated with the latest version of the Mondoo tools.  By using the install.mondoo.com API it looks for the latest version of the Mondoo Mac package and compares it to the installed version, if they differ it upgrades.  It will also insert an embedded local configuration file using a non-default file location so that other installations of Mondoo do not conflict with this installation.

Please note that you must upgrade the script with your Mondoo configuration before you can deploy it.

This is the installer Mondoo uses to continously scann all it's corperate workstations.

### Kandji

To deploy Evergreen on Kandji, follow these steps:

1. Obtain your Mondoo configuration file or create a new one and embed it into the ___evergreen.sh___ script.  To create a config, login to the [Mondoo Console](https://console.mondoo.com), nagivate to your space, then Settings and click the + button on the 'Service Accounts' tab.
2. Login to Kandji and navigate to 'Library'
3. Click the 'Add New' button, select 'Custom Scripts', and then click 'Add & Configure'
4. Name it 'Mondoo Evergreen Installer', select the appropriate Blueprint(s) to add it to.  Set the 'Execution Frequency' to 'Run daily'.  Do not enable Self Service.
5. Copy and paste the ___evergreen.sh___  script contents into the script box. 
6. Click 'Save'.  Done!

Once setup in the libary, you can visit the library items 'Status' tab to see the per device installation progress.

