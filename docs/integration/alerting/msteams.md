# Microsoft Teams

[Microsoft Teams](https://teams.microsoft.com/start) is a widely used communication tool. Mondoo can be configured to send alert messages to Microsoft Teams. To set the integration up, you will need to generate a new Microsoft Teams Webhook URL.

![Mondoo Microsoft Teams Alert](../../assets/msteams/msteams-alert.png)

## Configuration

- `url` - the Micosoft Teams Webhook URL. This URL can be obtained by adding a new `Connection` for your channel

## Setup

1. Open the Microsoft Teams app, select a team and a channel within that team
2. Click the `ellipsis icon` on the right side of the selected channel
3. Click `Connectors`

![Add a new Connection to your channel](../../assets/msteams/msteams-webhook-new.png)

4. Search the Incoming Webhook connector and click `Add` or `Configure`

![Select the Webhook](../../assets/msteams/msteams-webhook-add.png)

5. Provide a webhook name and an icon. Complete by clicking `Create`

![Create a new Webhook](../../assets/msteams/msteams-webhook-create.png)

6. Click on the `Copy` icon next to the generated webhook URL to use it in Mondoo

![Copy the confirmed URL](../../assets/msteams/msteams-webhook-created.png)

7. Open Mondoo Dashboard and switch to your space that you want to configure. Then select Settings -> Integrations and configure Microsoft Teams Webhook URL and Save

![Configure Microsoft Teams Webhook in Mondoo](../../assets/msteams/msteams-mondoo-configure.png)

8. Enable the Microsoft Teams integration

![Enable Microsoft Teams alerts in Mondoo](../../assets/msteams/msteams-mondoo-enable.png)
