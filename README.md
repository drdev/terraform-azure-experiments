# Prepare and install simple web application in Azure

1. [Goals](#goals)
2. [Description](#description)
3. [System requirements](#system-requirements)
4. [Test Chef cookbook](#test-chef-cookbook)
5. [To do](#to-do)


## Goals

1. Build infrastructure with Terraform or Azure CLI or PowerShell
2. Provision VMs with Web server Nginx and simple HTML page
3. Build Azure DevOps pipeline to deploy web app


## Description

1. Create an Azure Subscription (free for the fist 30 days with 200 USD credit) and an Azure DevOps environment (free)
2. Infrastructure with Terraform or Azure CLI or PowerShell:
   - the provisioning script/terraform module should accept a parameter – Environment name. Only “DEV” and “PROD” values should be allowed
   - 2 VMs (plan B1) if Environments is “DEV”, 3 VMs if Environment is “PROD”
   - 1 Network LB to load-balance the VMs created above
   - 1 app service plan (plan D1) with an web app
3. On the above VMs
   - create a basic page to show the host name and host it on the VMs (manually should be ok)
   - check the page content
   - make sure that the load balancer serves content from the both servers
4. With Azure DevOps
   - create a repository with some code (php, java, dotnet, python)
   - create a pipeline to build the code
   - create a pipeline to deploy the artifact from step above to the webapp created in step 1.
 

## System requirements

1. [Azure free account](https://azure.microsoft.com/en-us/free/)
2. [Azure DevOps environment (free)](https://azure.microsoft.com/en-us/services/devops/)
3. [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started#install-terraform)
3. [Azure CLI installed](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) and [configured](https://docs.microsoft.com/en-us/cli/azure/azure-cli-configuration)


## Build infrastructure within Azure Cloud

1. Configure Azure CLI, login to Azure Cloud

   ```bash
   az configure
   az login
   ```

2. Select environment. There are 2 options: 

   - either supply `-var-file` argument to `terraform` commands below, e.g.
     
     ```bash
     terraform apply -var-file="configs/prod.tfvars"
     ```
   - or make a link to config file ike below:
     ```bash
     ln -s configs/prod.tfvars terraform.tfvars
     ```
3. Review execution plan and apply changes:
   ```bash
   terraform plan
   terraform apply
   ```
4. Use `verify` output value to make sure load balancing works as expected. Wait until both `dev-vm-0` and `dev-vm-1` appeared in output and kill it with `Ctrl-C`, e.g.
   ```bash
   while true; do curl -s http://20.61.250.23; sleep 5; done
   ```
5. (Optional) To help save money, once you've proven that the exercise works you may either stop or decommission the resources
   ```bash
   terraform destroy
   ```

## To do

1. Add Azure Service Plan for web application
2. Build Azure DevOps pipelines to deploy an app to infrastructure
3. Decide on file structure and resources organization
