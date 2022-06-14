## App Service logging to blob

A simple example how you can configure your App Service App to log directly to a blob storage container.

If you configure the logging in the Azure portal, the portal automatically creates a SAS url for your logging container. However with Terraform, you have to take an additional step.

After creating your container, you need to create a data resource called `azurerm_storage_account_blob_container_sas` to generate a Shared Access Signature. After that, we reformat it to the format App Service expects: starting with the blob storage endpoint, followed by the container name and finally appended with the SAS. Finally we store the create SAS url to a keyvault, so we can verify its formatted properly.

After this we can just pass it to the App Service `azure_blob_storage`-block and our logs automatically start to flow to the container specified.