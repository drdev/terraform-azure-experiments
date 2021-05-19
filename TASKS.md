# TASKS

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
5. Terms:
   - Deadline – 31.05.2021
   - Complete as many tasks as possible
   - The task should be pushed to a Git repository and shared with us and should contain a readme with instructions on how to reproduce the task
   - to help save money, once you've proven that the exercise works you may either stop or decommission the resources
   - In case of questions, please reach out to Andrei.Drumov@endava.com and Sergiu.Cibotaru@endava.com
