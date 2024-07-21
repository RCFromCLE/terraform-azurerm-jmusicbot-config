# terraform-azurerm-jmusicbot-config

This repository automates the deployment of JMusicBot on Azure using Terraform and GitHub Actions.

![Deploy Function](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config/actions/workflows/deploy-function.yml/badge.svg)
[![Check for Module Update and TF Apply](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config/actions/workflows/trigger-terraform-apply.yml/badge.svg)](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config/actions/workflows/trigger-terraform-apply.yml)


### Prerequisites

- Azure subscription
- GitHub account
- Terraform Cloud account
- Azure CLI
- Discord Bot with necessary permissions and token

### Setup Instructions

1. Fork and clone this repository:

```bash
   git clone https://github.com/<your-username>/terraform-azurerm-jmusicbot-config.git
   cd terraform-azurerm-jmusicbot-config
```

**Note**: You will need to do this with the jdiscord-kv-config directory as well. Once complete, You will have a total of two Terraform Cloud workspaces, one for the Azure Key Vault and one for the Azure VM. The Azure Key Vault workspace will be created first and the Azure VM workspace will be created second. The Azure VM workspace will be dependent on the Azure Key Vault workspace and should be configured with a run trigger to run after the Azure Key Vault workspace.

2. Create Azure Service Principal:

```powershell
   az login
   az ad sp create-for-rbac --name "tf-jdiscord-gh-update-pipeline" --role contributor --scopes /subscriptions/<your-subscription-id>
```

3.  Update main.tf with your Terraform Cloud details for borth workspaces. Below is an example of the main.tf's terraform cloud block for the primary workspace. You will need to repeat this process for the keyvault workspace as well.

```hcl
   terraform {
     cloud {
       organization = "YourOrganization"
       workspaces {
         name = "azure-jmusicbot"
       }
     }
   }
```
4. Fill in terraform.tfvars with your Azure and Discord details and run terraform init. 

terraform.tfvars for primary workspace:

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

terraform.tfvars for keyvault workspace:

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
You can use **set_workspace_variable.ps1** to automagically create variables in the TF Cloud Workspace to save time. Simply fill out your Terraform API token, place the script in the same directory as terraform.tfvars and run the script.

5. **Configuring the Terraform Cloud workspaces**:

Verify after running terraform init for the kv and primary config you can see the workspaces in Terraform Cloud. They will not have a run status as this example until after the first run. 

   - Create a variable set with 
   ***ARM_CLIENT_ID*** 
   ***ARM_CLIENT_SECRET*** 
   ***ARM_SUBSCRIPTION_ID***
   ***ARM_TENANT_ID*** 
   - Set each  as env variables
   - Assign this variable set to both workspaces

   At this point, you should have each workspace setup with the workspace and environment variables required.
![alt text](image.png)
   - Create a variable set with 
   ***ARM_CLIENT_ID*** 
   ***ARM_CLIENT_SECRET*** 
   ***ARM_SUBSCRIPTION_ID***
   ***ARM_TENANT_ID*** 
   - Set each  as env variables
   - Assign this variable set to both workspaces

   At this point, you should have each workspace setup with the workspace and environment variables required.

![alt text](images/image-1.png)
![alt text](images/image-4.png)
For each workspace, enable VCS integration and select your GitHub config repository, be sure to set the keyvault workspace to use the correct working directory, jdiscord-kv-config.
![alt text](images/image-3.png)
In the primary orksapce, set the run trigger to run after the keyvault workspace.
![alt text](images/image-2.png)

You can now trigger a run by pushing a change to the main branch of the keyvault config directory or by manually running a plan and apply in the keyvault workspace through the Terraform Cloud UI. Once the keyvault workspace has completed, the primary workspace will automatically trigger and run. Once completed, you should have a fully deployed JMusicBot, verify the bot is running by checking the Azure VM, function app, and that the bot is online in Discord and can play music.

6.  Setup GitHub Actions Secrets for workflows. VSCode > GitHub Actions Extension > Settings > Secrets:
<br>
    - ***AZURE_CREDENTIALS***: Azure Service Principal credentials
    - ***AZURE_FUNCTIONAPP_PUBLISH_PROFILE***: Azure Function App publish profile
    - ***AZURE_FUNCTION_APP_NAME***: Azure Function App name
    - ***AZURE_RESOURCE_GROUP***: Azure Resource Group name
    - ***AZURE_VM_NAME***: Azure VM name
    - ***PAT_TOKEN***: GitHub Personal Access Token
    - ***TF_API_TOKEN***: Terraform Cloud API Token
    - ***TF_CLOUD_ORGANIZATION***: Terraform Cloud organization name
    - ***TF_WORKSPACE_NAME***: Terraform Cloud workspace name
   <br>

7.  GitHub Actions Workflows:
   - deploy-function.yml: Deploys Azure Function on push to master
   - Check for Module Update and TF Apply.yml: Daily check for updates, applies Terraform changes

### GitHub Actions Details

#### deploy-function.yml
- Triggers: Push to master, manual
- Environment: dev
- Steps: Checkout code, Setup Node.js, Install dependencies, Build and test, Deploy to Azure Functions

#### Check for Module Update and TF Apply.yml

**Note**: If you manually trigger this workflow, it will run regardless of if there is an update to jmusicbot, scheduled runs will only run if there is an update to jmusicbot.
- Triggers: Daily at 5:30 AM EST, manual
- Steps: 
  - Check for updates to the terraform-azurerm-jmusicbot module and JMusicBot jar
  - Update configurations
  - Azure login and Terraform init to download latest terraform-azurerm-jmusicbot module
  - VM state management 
  - Terraform operations - Plan, Apply
  - Conditions: If updates found, If VM is off, If VM is on

#### Module Structure

This project uses the [`terraform-azurerm-jmusicbot`](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot) module, which sets up the following Azure resources:

- Azure Virtual Machine: Runs the JMusicBot application
- Virtual Network and Subnet: Provides network isolation
- Network Security Group (NSG): Controls inbound and outbound traffic
- Public IP: Allows external access to the VM
- Azure Key Vault: Securely stores sensitive information in the project
- Azure Function App: Manages the VM lifecycle based on Discord activity

#### Automatic Updates

Checks for new module and jar releases, updates configurations, and triggers Terraform apply if updates are found.

#### VM Management

The workflow intelligently manages the VM's power state during updates:
1. Pre-update Check: Verifies the VM's current power state.
2. Activation: If the VM is off, the workflow starts it before applying changes.
3. Update Process: Applies necessary updates and configuration changes while the VM is running.
4. State Restoration: After updates, if the VM was initially off, the workflow returns it to a powered-off state.
5. Always-On Option: For scenarios requiring constant uptime, the workflow can be configured to leave the VM running.

#### Monitoring and Troubleshooting

Monitor GitHub Actions tab for workflow status. For issues:
1. Check GitHub Actions logs
2. Verify repository secrets
3. Confirm Azure credentials and permissions
4. Review Terraform Cloud workspace runs

Open an issue in this repository for persistent problems.

![GitHub Actions](https://github.com/RCFromCLE/terraform-azurerm-jmusicbot-config/raw/master/images/github-actions.png)
```