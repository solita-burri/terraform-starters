# YAML pipeline examples for Azure DevOps


`plan-and-apply.yml` is a pipeline that creates a snapshot from the terraform code, excutes a plan and then applies it. You should create a [manual review](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops#approvals) before the apply-phase by creating an environment(s) named `'my_project_${{ parameters.environment }}'` and defining required approvals.

## Stages:

### Parameters:
- `environment` is used in namings and fetching correct environmental variables
- `variableGroupName` is the name of the [variable group](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml) containing the required secrets. Consider linking the group to a key vault instead of storing the secrets inside DevOps

Explanations what happens (and why) in different stages
### build_environment:
Takes a snapshot of the code to ensure both plan and apply phases use the same baseline. This could be avoided if we would pass the plan from the planning phase to the apply phase. However this would mean we have to store the plan file (which [may contain secrets](https://github.com/hashicorp/terraform/issues/29535)) as an artifact. The downside to our solution is that if something changes in Azure between the plan and apply, the reviewed plan might not reflect the reality. However this was an acceptable risk for us.

### terraform_plan:
Pretty standard terraform plan. Downloads first the code snapshot from the artifacts. Expects that there are environment specific variables in the path `config/tf-vars/<ENV>.tfvars`. Also expects an [Azure service principal credentials in the environment](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret#configuring-the-service-principal-in-terraform). The parameter `-detailed-exitcode` is used to identify if the plan causes any changes to the infrastructure. 

### terraform_apply:
Is executed only if the exit code from the previous step equals to 2 (=plan successful and contains changes). Downloads again the code snapshot from artifacts and then executes plan+apply without interventions.