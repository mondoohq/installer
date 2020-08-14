# Slack

[Slack](https://slack.com/) is a widely used communication tool. Mondoo can be configured to send alert messages to Slack. To set the integration up, you will need to generate a new Slack Webhook URL.

![Mondoo Slack Alert](../../assets/slack/slack-alert.png)

## Configuration

- `url` - the Slack Webhook URL. This URL can be obtained by adding a new [Incoming WebHooks app](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks) integration

## Setup

1. Create a new [Incoming WebHooks app](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks)

![Slack Directory](../../assets/slack/slack-webhook-directory.png)

2. Enter the Slack channel and confirm that you want to create a new Webhook URL

![Slack Webhook Directory](../../assets/slack/slack-webhook-create.png)

3. Copy the generated Webhook URL

![Slack Webhook Directory](../../assets/slack/slack-webhook-created.png)

4. Further configure the details of the Webhook

![Configure Slack Webhook](../../assets/slack/slack-webhook-configure.png)

3. Open Mondoo Dashboard and switch to your space that you want to configure. Then select Settings -> Integrations and configure Slack Webhook URL and Save

![Configure Slack in Mondoo](../../assets/slack/slack-mondoo-configure.png)

5. Enable the Slack integration

![Enable Slack in Mondoo](../../assets/slack/slack-mondoo-enable.png)
