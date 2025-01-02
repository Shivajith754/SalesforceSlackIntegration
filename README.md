# Salesforce-Slack Integration for Real-Time Lead Notifications

## Overview

This project seamlessly integrates **Salesforce** with **Slack** to deliver real-time notifications to designated Slack channels whenever a new lead is created in Salesforce. This integration ensures that sales teams are promptly informed, enabling immediate follow-ups and enhancing overall sales efficiency.

## Features

- **Real-Time Notifications:** Automatically send detailed lead information to a specified Slack channel upon lead creation
- **Custom Message Formatting:** Utilize Slack's rich formatting for clear and informative messages
- **Error Handling & Logging:** Robust mechanisms to handle API call failures and log all notification attempts
- **Retry Mechanism:** Implements exponential backoff retries to manage rate limits and transient failures
- **Secure Credential Management:** Store Slack API tokens securely using Salesforce Custom Settings
- **Comprehensive Testing:** Apex test classes achieve 100% pass rate, ensuring reliability and compliance with Salesforce's code coverage requirements

## Technologies Used

- **Salesforce:**
  - Apex Classes, Interfaces, and Triggers
  - Custom Settings
  - Custom Objects
- **Slack:**
  - Slack API, Slack Apps
- **Development Tools:**
  - Visual Studio Code (VS Code) with Salesforce Extensions
  - Salesforce CLI
  - Git, GitHub

## Prerequisites

- **Salesforce Environment:**
  - Salesforce Developer Edition or Production Org with permissions to create Custom Settings, Remote Site Settings, Apex Classes, Triggers, and Custom Objects
- **Slack Workspace:**
  - Ability to create and configure Slack apps
  - Permissions to install Slack apps and manage channels
- **Development Tools:**
  - [Visual Studio Code](https://code.visualstudio.com/)
  - [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli)
  - [Git](https://git-scm.com/downloads)
- **Slack Bot Token:**
  - Obtained from your Slack app's **OAuth & Permissions** page

## Project Structure

```
force-app/
└── main/
    └── default/
        ├── classes/
        │   ├── LeadTriggerHandler.cls
        │   ├── LeadTriggerHandler.cls-meta.xml
        │   ├── LeadTriggerHandlerTest.cls
        │   ├── LeadTriggerHandlerTest.cls-meta.xml
        │   ├── Logger.cls
        │   ├── Logger.cls-meta.xml
        │   ├── SlackConfig.cls
        │   ├── SlackConfig.cls-meta.xml
        │   ├── SlackConfigManager.cls
        │   ├── SlackConfigManager.cls-meta.xml
        │   ├── SlackRetryScheduler.cls
        │   ├── SlackRetryScheduler.cls-meta.xml
        │   ├── SlackRetrySchedulerTest.cls
        │   ├── SlackRetrySchedulerTest.cls-meta.xml
        │   ├── SlackService.cls
        │   ├── SlackService.cls-meta.xml
        │   ├── SlackServiceTest.cls
        │   └── SlackServiceTest.cls-meta.xml
        ├── objects/
        │   └── Slack_Notification_Log__c/
        │       ├── fields/
        │       │   ├── Lead__c-field-meta.xml
        │       │   ├── Response_Message__c-field-meta.xml
        │       │   ├── Status__c-field-meta.xml
        │       │   └── Timestamp__c-field-meta.xml
        │       └── Slack_Notification_Log__c.object-meta.xml
        ├── triggers/
        │   ├── LeadTrigger.trigger
        │   └── LeadTrigger.trigger-meta.xml
        └── manifest/
            └── package.xml
```

## Installation and Setup

### 1. Salesforce Configuration

#### a. Create Remote Site Setting

1. **Navigate to Remote Site Settings:**
   - Log in to your Salesforce org
   - Click on the **Gear Icon** (⚙️) > **Setup**
   - In the **Quick Find** box, type "Remote Site Settings" and select it

2. **Create New Remote Site:**
   - Click "New Remote Site"
   - **Remote Site Name:** `Slack_API_Remote_Site`
   - **Remote Site URL:** `https://slack.com/api`
   - **Description:** `Slack API Endpoint for Sending Messages`
   - **Active:** Checked
   - Click "Save"

#### b. Create Custom Settings

1. **Navigate to Custom Settings:**
   - From **Setup**, type "Custom Settings" in the **Quick Find** box and select it

2. **Create New Custom Setting:**
   - Click "New"
   - **Label:** `Slack Settings`
   - **Object Name:** `Slack_Settings`
   - **Setting Type:** `Hierarchy`
   - **Visibility:** `Protected`
   - Click "Save"

3. **Add Custom Fields:**
   - **Slack_Bot_Token__c:**
     - Click "New" in the **Custom Fields** section
     - **Data Type:** `Text (Encrypted)`
     - **Field Label:** `Slack Bot Token`
     - **Field Name:** `Slack_Bot_Token`
     - **Length:** `50`
     - Click "Next", set field-level security as needed, and "Save"
 4. **Set Slack Bot Token:**
   - Click **"Manage"** next to `Slack_Settings`.
   - Click "New" in Default Organization Level Value
   - Enter your **Slack Bot Token**.
   - Click **"Save"**.
      

### 2. Slack Configuration

#### a. Create a Slack App

1. **Navigate to Slack API:**
   - Go to [Slack API: Applications](https://api.slack.com/apps)

2. **Create a New App:**
   - Click "Create New App"
   - Choose "From scratch"
   - **App Name:** `SalesforceIntegrationBot`
   - **Development Slack Workspace:** Select your workspace
   - Click "Create App"

#### b. Configure App Permissions

1. **Bot Token Scopes:**
   - Navigate to **OAuth & Permissions** in your Slack app settings
   - Under **Scopes**, add the following **Bot Token Scopes**:
     - `chat:write` (to send messages)
     - `channels:read` (to read channel info)
     - `groups:read` (if sending to private channels)

2. **Install the App:**
   - Still under **OAuth & Permissions**, click "Install App to Workspace"
   - Authorize the app
   - Copy the **Bot User OAuth Token** (starts with `xoxb-`)

### 3. Development Environment Setup

#### a. Clone the Repository

```bash
git clone https://github.com/yourusername/SalesforceSlackIntegration.git
cd SalesforceSlackIntegration
```

#### b. Authenticate Salesforce Org

```bash
sfdx force:auth:web:login -a DevOrg
```

#### c. Push Source to Salesforce

```bash
sfdx force:source:push -u DevOrg
```

## Usage

Once set up, the integration operates automatically:

1. **Create a New Lead in Salesforce:**
   - Navigate to Leads
   - Click "New", fill in the required fields, and save

2. **Receive Slack Notification:**
   - The designated Slack channel receives a formatted message with the lead details

Example Slack Notification:
```
🎉 *New Lead Created!*
*Name:* John Doe
*Email:* john.doe@example.com
*Company:* Acme Corp.
*Interest:* Product X
<View in Salesforce|https://your-salesforce-instance.salesforce.com/00Qxxxxxxxxxxxx>
```

## Testing

Run Apex tests using:

```bash
sfdx force:apex:test:run -u DevOrg -c -r human
```

Test results should show:
- All tests passing
- Coverage ≥75%
- Proper error handling validation

## Troubleshooting

### Common Issues

1. **Slack Notifications Not Appearing:**
   - Verify Slack Channel ID in Custom Settings
   - Ensure bot is invited to the channel
   - Check Bot Token validity
   - Review debug logs

2. **API Callout Failures:**
   - Confirm Remote Site Settings are active
   - Verify Custom Settings configuration
   - Check user permissions
   - Monitor network access

3. **Rate Limiting:**
   - Monitor Slack_Notification_Log__c for status
   - Review retry scheduler functionality

## License

This project is licensed under the [MIT License](LICENSE.txt)
