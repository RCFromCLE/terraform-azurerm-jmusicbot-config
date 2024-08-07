# terraform-azurerm-jmusicbot-config
![Deploy Function](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config/actions/workflows/deploy-function.yml/badge.svg)
[![Check for Module Update and TF Apply](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config/actions/workflows/trigger-terraform-apply.yml/badge.svg)](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config/actions/workflows/trigger-terraform-apply.yml)

## Introduction

This configuration repository automates the deployment of JMusicBot on Azure using Terraform, Terraform Cloud, and GitHub Actions.

![Terraform, GitHub, Azure, logo](images/tf-gh-azure.png)

### What is JMusicBot?

![JMusicBot Logo](images/jmusicbot.png)

JMusicBot is an open-source Discord music bot that plays music in voice channels from various sources, primarily YouTube. It is a Java application that requires a Linux or Windows machine to run. The bot is controlled via commands in a Discord text channel. For more information, see the [JMusicBot Wiki](https://jmusicbot.com/).


### Prerequisites

- Azure subscription
- VS Code with the below extensions:
   - Azure Tools
   - PowerShell
   - GitHub Actions
   - Terraform - HashiCorp
   - HCP - Terraform
- GitHub account
- Terraform Cloud account and Organization
- Azure CLI installed locally
- [Discord Application (Bot) with necessary permissions and token](https://jmusicbot.com/getting-a-bot-token/) 

## Setup Instructions

1. Launch VS Code and open the PowerShell Terminal. Fork and clone this repository:

```powershell
   git clone https://github.com/<your-username>/terraform-azurerm-jmusicbot-config.git
   cd terraform-azurerm-jmusicbot-config/jdiscord-kv-config
```

2. Create Azure Service Principal. Be sure to take note of the client_id upon creation. Open the Azure portal and create a secret for this registered application (SPN), hold on to this secret we will use it soon. 

```powershell
   az login
   az ad sp create-for-rbac --name "tf-jdiscord-gh-update-pipeline" --role contributor --scopes /subscriptions/<your-subscription-id>
```

3. Run terraform login and sign in to your TF Cloud organization. Set each main.tf's terraform block to contain the correct organization and workspace information from your TF Cloud org.

**Two Terraform Cloud Workspaces**
   - **Azure Key Vault Workspace**: Created first, contains secrets needed in Azure to deploy and run JMusicBot.
   - **Azure Primary Workspace**: Created second and dependent on the Azure Key Vault workspace will deploy JMusicBot and its supporting resources.

```powershell
 terraform login
```

```hcl
   terraform {
     cloud {
       organization = "YourOrganization"
       workspaces {
         name = "azure-jmusicbot-kv"
       }
     }
   }
```
```hcl
   terraform {
     cloud {
       organization = "YourOrganization"
       workspaces {
         name = "azure-jmusicbot-primary"
       }
     }
   }
```

4. Configure Terraform Variables

Fill in `terraform.tfvars` with your Azure and Discord details and run `terraform init` for each workspace.

#### Key Vault Workspace - jdiscord-kv-config - (`terraform.tfvars` and `main.tf`):

```hcl
subscription_id = ""
location = "East US"
kv_resource_group_name = "jdiscord-kv-rg"
key_vault_name = "jdiscord-kv"
discord_bot_token = ""
discord_bot_owner = ""
discord_bot_prefix = "!"
additional_access_policy_object_id = ""
```
![main.tf of kv workspace](images/maintf_kv_config.png)
#### Primary Workspace - root directory - (`terraform.tfvars` and `main.tf`):

```hcl
sub                 = ""
afk_channel_id      = ""
azure_client_id     = ""
azure_client_secret = ""
azure_tenant_id     = ""
discord_bot_owner   = ""
discord_bot_prefix  = "!"
discord_bot_token   = ""
general_channel_id  = ""
music_channel_id    = ""    
```
```hcl
module "jmusicbot" {
  source  = "RCFromCLE/jmusicbot/azure"
  version = "v2.0.0"

  # required variables
  azure_tenant_id     = var.azure_tenant_id
  sub                 = var.sub
  discord_bot_token   = var.discord_bot_token
  discord_bot_owner   = var.discord_bot_owner
  general_channel_id  = var.general_channel_id
  music_channel_id    = var.music_channel_id
  afk_channel_id      = var.afk_channel_id
  azure_client_id     = var.azure_client_id
  azure_client_secret = var.azure_client_secret

  # optional variables
  rg                 = var.rg
  rg_loc             = var.rg_loc
  net                = var.net
  subnet             = var.subnet
  pub_ip             = var.pub_ip
  nic_name           = var.nic_name
  nsg                = var.nsg
  vm_name            = var.vm_name
  vm_size            = var.vm_size
  vm_image_publisher = var.vm_image_publisher
  vm_image_offer     = var.vm_image_offer
  vm_image_sku       = var.vm_image_sku
  vm_image_version   = var.vm_image_version
  os_disk_name       = var.os_disk_name
  vm_admin_username  = var.vm_admin_username
}
```
**Note**: You can use `set_workspace_variable.ps1` to automatically create variables in the Terraform Cloud Workspace from your local variables. Simply fill out your Terraform API token, org name, and workspace name, place the script in the same directory as `terraform.tfvars`, and run the script.

5. Configure Terraform Cloud Workspaces

After running `terraform init` for both the Key Vault and primary configurations, verify that you can see the workspaces in Terraform Cloud. They will not have a run status until after the first run.

![Terraform Cloud Workspaces](images/tf_cloud_workspaces.png)

6. Create a variable set with the following environment variables:
   - `ARM_CLIENT_ID`
   - `ARM_CLIENT_SECRET`
   - `ARM_SUBSCRIPTION_ID`
   - `ARM_TENANT_ID`

7. Assign this variable set to both workspaces.

At this point, you should have each workspace set up with the required workspace and environment variables.

![Terraform Cloud Variables](images/image-4.png)

8. Enable VCS integration for each workspace:
   - Select your GitHub config repository
   - For the Key Vault workspace, set the correct working directory: `jdiscord-kv-config`

![VCS Integration](images/image-3.png)

9. In the primary workspace, set the run trigger to execute after the Key Vault workspace completes.

**Run Trigger Configuration**: Configure the Azure primary workspace with a run trigger to execute after the Azure Key Vault workspace completes its run.

![Run Trigger](images/image-2.png)

### Deployment

You can now trigger a run by:

- Pushing a change to the main branch of the Key Vault config directory, or
- Manually run a plan and apply in the Key Vault workspace through the Terraform Cloud UI

Once the Key Vault workspace has completed, the primary workspace will automatically trigger and run.

You now need to complete step 10 and setup the secrets for your GitHub Action. Once you have the secrets in place run the deploy-function workflow.

### Updating Secrets After Deployment

To update the Discord token or your Azure credentials, follow these steps:

 - Go to Terraform Cloud and update the workspace variables for the key vault workspace.
 - Trigger a run in the key vault workspace. This will update the secrets in  JMusicBot project's Key Vault. The updated secrets will be referenced in the primary workspace. The primary workspace will trigger a run and update the Azure resources.

Now that your solution is deployed we need to setup the secrets each GitHub Action workflow will require. This is so we can keep JMusicBot running the latest version as sometimes only the latest version is the working version and manually performing updates can suck.

10.  ### Setup GitHub Actions Secrets for Workflows

- **`AZURE_CREDENTIALS`**: Azure Service Principal credentials
  - [How to create and configure Azure Service Principal credentials](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal)
- **`AZURE_FUNCTIONAPP_PUBLISH_PROFILE`**: Azure Function App publish profile
  - [How to get the Azure Function App publish profile](https://learn.microsoft.com/en-us/visualstudio/azure/how-to-get-publish-profile-from-azure-app-service?view=vs-2022)
- **`AZURE_FUNCTION_APP_NAME`**: Azure Function App name
- **`AZURE_RESOURCE_GROUP`**: Azure Resource Group name
- **`AZURE_VM_NAME`**: Azure VM name
- **`PAT_TOKEN`**: GitHub Personal Access Token
   - [How to create a GitHub Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-personal-access-token-classic)
- **`TF_API_TOKEN`**: Terraform Cloud API Token
   - [How to create a Terraform Cloud API Token](https://aws-quickstart.github.io/workshop-terraform-modules/40_setup_cloud9_ide/43_setup_tfc_api_token.html)
- **`TF_CLOUD_ORGANIZATION`**: Terraform Cloud organization name
   - [How to set up your Terraform Cloud organization](https://app.terraform.io/public/signup/account?utm_source=learn&ajs_aid=18f0a77a-627a-43ee-a824-d34056b25463&product_intent=terraform)
- **`TF_WORKSPACE_NAME`**: Terraform Cloud workspace name
   - [How to create a Terraform Cloud workspace](https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-workspace-create)### Verification

After adding your secrets, run deploy-function, upon successful function deployment you should have a fully operational JMusicBot project. 

### Verification

Verify the deployment by:

-  Checking the Azure VM
-  Confirming the function app is running
-  Ensuring the bot is online in Discord and can play music
-  Confirming the bot joins when you have at least one user in the music channel
-  Confirm bot responds to "start music bot" within 5 minutes and the bot joins within 6 minutes.

### GitHub Actions Workflows:
   - ###### File:  `deploy-function.yml` | Title - deploy-function | 
   - ###### File:  `trigger-terraform-apply.yml` | Title - Check for JMusicBot Update and TF Apply

##### deploy-function
![Deploy Function](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config/actions/workflows/deploy-function.yml/badge.svg)
- Description: Deploys the Azure Function App that manages the VM lifecycle based on Discord activity. Do this after the initial deployment of the JMusicBot.
- Triggers: Push to master, manual
- Environment: dev
- Steps: Checkout code, Setup Node.js, Install dependencies, Build and test, Deploy to Azure Functions

##### Check for Module Update and TF Apply
[![Check for Module Update and TF Apply](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config/actions/workflows/trigger-terraform-apply.yml/badge.svg)](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config/actions/workflows/trigger-terraform-apply.yml)
- Description: Checks for updates to the terraform-azurerm-jmusicbot module and JMusicBot jar, updates configurations, and triggers Terraform apply if updates are found.
- Triggers: Daily at 5:30 AM EST, manual
- Steps: 
  - Check for updates to the terraform-azurerm-jmusicbot module and JMusicBot jar
  - Update configurations
  - Azure login and Terraform init to download the latest terraform-azurerm-jmusicbot module
  - VM state management
  - Function app state management
  - Terraform operations - Plan, Apply
  - Conditions: If updates are found, If VM is off, If VM is on

*Note*: If you manually trigger this workflow, it will run and terraform apply regardless of if there is an update to JMusicBot, scheduled runs will only run if there is an update to [`terraform-azurerm-jmusicbot`](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot).

#### Module Structure

This project uses the [`terraform-azurerm-jmusicbot`](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot) module, which sets up the following Azure resources:

- Azure Virtual Machine: Runs the JMusicBot application
- Virtual Network and Subnet: Provides network isolation
- Network Security Group (NSG): Controls inbound and outbound traffic
- Public IP: Allows external access to the VM
- Azure Key Vault: Securely stores sensitive information in the project
- Azure Function App: Manages the VM lifecycle based on Discord activity

#### Automatic Updates

Checks for new module and jar releases, updates, configurations, and triggers Terraform apply if updates are found.

#### VM Management

The workflow intelligently manages the VM and Function app's power state when it runs.

 - Pre-update Check: Verifies the VM and function apps  current power state.
 - Activation: If the VM and/or Function app is off, the workflow starts before applying changes.
 - Update Process: Applies necessary updates and configuration changes while the VM is running.
 - State Restoration: After updates, if the VM and/or Function app was initially off, the workflow returns it to a powered-off state.

## Troubleshooting

1. Check GitHub Actions logs
2. Check function app log stream and invocation logs
3. Use the serial console option under help and support section of the VM to connect and confirm the jdiscordbot.service is running and connected to your Discord server properly.
4. Confirm you are using the correct secrets in each of your Terraform Cloud workspace variables sections.
5. Verify GitHub actions repository secrets
6. Confirm Azure credentials and permissions
7. Review Terraform Cloud workspace runs

See https://jmusicbot.com/troubleshooting/ for additional troubleshooting information.

Open an issue in this repository or the [`terraform-azurerm-jmusicbot`](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot) for persistent problems.
