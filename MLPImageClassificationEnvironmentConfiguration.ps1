# instructions and documentation for this solution have been moved to the Read Me file in the solution

while([string]::IsNullOrWhiteSpace($subscription))
  {$subscription= Read-Host -Prompt "Input the name of the subscription where this solution will be deployed"}

$modelResourceGroupName = Read-Host -Prompt 'Input the name of the resource group that you want to create for this installation of the model.  (default=MLPObjectDetection)'
  if ([string]::IsNullOrWhiteSpace($modelResourceGroupName)) {$modelResourceGroupName = "MLPObjectDetection"}

  while([string]::IsNullOrWhiteSpace($modelStorageAccountName))
  {$modelStorageAccountName= Read-Host -Prompt "Input the name of the azure storage account you want to create for this installation of MLP Object Detection model. Note this must be a name that is no longer than 24 characters and only uses lowercase letters and numbers and is unique across all of Azure"
  if ($modelStorageAccountName.length -gt 24){$modelStorageAccountName=$null
  Write-Host "Storage account name cannot be longer than 24 charaters." -ForegroundColor "Red"}
  if(-Not ($modelStorageAccountName -cmatch "^[a-z0-9]*$")) {$modelStorageAccountName=$null
  Write-Host "Storage account name can only have lowercase letters and numbers." -ForegroundColor "Red"}
  }
  
while([string]::IsNullOrWhiteSpace($ModelAppName))
  {$ModelAppName= Read-Host -Prompt "Input the name for the azure function app you want to create for your analysis model. Note this must be a name that is unique across all of Azure"}

$modelLocation = Read-Host -Prompt 'Input the Azure location, data center, where you want this solution deployed.  Note, if you will be using Python functions as part of your solution, As of 8/1/19, Python functions are only available in eastasia, eastus, northcentralus, northeurope, westeurope, and westus.  If you deploy your solution in a different data center network transit time may affect your solution performance.  (default=westus)'
  if ([string]::IsNullOrWhiteSpace($modelLocation)) {$modelLocation = "westus"}

$modelStorageAccountKey = $null

if (az group exists --name $modelResourceGroupName) `
  {Write-Host "Deleting resource group." -ForegroundColor "Green" `
  az group delete `
	  --name $modelResourceGroupName `
	  --subscription $subscription `
	  --yes -y}

Write-Host "Creating Resource Group: " $modelResourceGroupName  -ForegroundColor "Green"

az group create `
  --name $modelResourceGroupName `
  --location $modelLocation 

Write-Host "Creating storage account: " $modelStorageAccountName  -ForegroundColor "Green"

az storage account create `
    --location $modelLocation `
    --name $modelStorageAccountName `
    --resource-group $modelResourceGroupName `
    --sku Standard_LRS

Write-Host "Getting storage account key." -ForegroundColor "Green"

$modelStorageAccountKey = `
	(get-azureRmStorageAccountKey `
		-resourceGroupName $modelResourceGroupName `
		-AccountName $modelStorageAccountName).Value[0]

Write-Host "Creating function app: " $ModelAppName -ForegroundColor "Green"

az functionapp create `
  --name $ModelAppName `
  --storage-account $modelStorageAccountName `
  --consumption-plan-location $modelLocation `
  --resource-group $modelResourceGroupName `
  --os-type "Linux" `
  --runtime "python"

Write-Host "Creating cognitive services account." $ModelAppName"Training" " and " $ModelAppName"Prediction" -ForegroundColor "Green"
Write-Host "Note: Azure custom vision is only available in a limited set of regions.  If you have selected aq region for your function app that is not supported by custom vision you will be prompted for a new location."    

if ("southcentralus", "westus2", "eastus", "eastus2", "northeurope", "westeurope", "southeastasia", "japaneast", "australiaeast", "centralindia", "uksouth","northcentralus" -contains $modelLocation) `
  {$modelCogServicesLocation = $modelLocation}
else
  {
    $modelCogServicesLocation = Read-Host -Prompt 'Input the Azure location, data center, where you want your cog services feature deployed.  Note, as of 8/29/19, custom vision features are only available in southcentralus, westus2, eastus, eastus2, northeurope, westeurope, southeastasia, japaneast, australiaeast, centralindia, uksouth, northcentralus.  (default=westus2)'
    if ([string]::IsNullOrWhiteSpace($modelCogServicesLocation)) {$modelCogServicesLocation = "westus2"}  
  }

$accountName = $ModelAppName + "Training"

az cognitiveservices account create `
    --name $accountName `
    --resource-group $modelResourceGroupName `
    --kind CustomVision.Training `
    --sku S0 `
    --location $modelCogServicesLocation `
    --yes

az cognitiveservices account create `
    --name $ModelAppName"Prediction" `
    --resource-group $modelResourceGroupName `
    --kind CustomVision.Prediction `
    --sku S0 `
    --location $modelCogServicesLocation `
    --yes

$cog_services_training_key = `
  (get-AzureRmCognitiveServicesAccountKey `
    -resourceGroupName $modelResourceGroupName `
    -AccountName $accountName).Key1

Write-Host "Creating app config setting: SubscriptionKey." -ForegroundColor "Green"

az functionapp config appsettings set `
    --name $ModelAppName `
    --resource-group $modelResourceGroupName `
    --settings "SubscriptionKey=$cog_services_training_key"

Write-Host "Creating app config setting: ProjectID for cognitive services." -ForegroundColor "Green"

$url = "https://westus2.api.cognitive.microsoft.com/customvision/v3.0/training/projects"

  $headers = @{
      'Training-Key' = $cog_services_training_key }

$projects = (Invoke-RestMethod -Uri $url -Headers $headers -Method Get)
$projectName = ($projects | Where-Object {$_."name" -eq $accountName + "CustomVisionProject"} | Select-Object -Property name).name
$generatedProjectName = $ModelAppName + "CustomVisionProject"

if ($null -ne $projectName) {
  while($projectName -eq $generatedProjectName)
  {
    Write-Host "A cognitive services project already exists with the name: " $generatedProjectName -ForegroundColor "Red"

    $projectName= Read-Host -Prompt "Please enter a different cognitive services project name or delete the existing project with the same name using the Cognitive services portal."
  }
}
else {
  $projectName = $generatedProjectName
}

Write-Host "Creating cognitive services custom vision project: " $projectName -ForegroundColor "Green"

$url = "https://" + $modelCogServicesLocation + ".api.cognitive.microsoft.com/customvision/v3.0/training/projects?name=" + $projectName
$url

$headers = @{}
$headers.add("Training-Key", $cog_services_training_key)
$headers

$url

Invoke-RestMethod -Uri $url -Headers $headers -Method Post | ConvertTo-Json

#get the project id to set as a config value
$url = "https://westus2.api.cognitive.microsoft.com/customvision/v3.0/training/projects"

  $headers = @{
      'Training-Key' = $cog_services_training_key }

$projects = (Invoke-RestMethod -Uri $url -Headers $headers -Method Get)
$projectId = ($projects | Where-Object {$_."name" -eq $projectName} | Select-Object -Property id).id

az functionapp config appsettings set `
    --name $ModelAppName `
    --resource-group $modelResourceGroupName `
    --settings "ProjectID=$projectId"

Write-Host "Creating app config setting: TrainingKey for cognitive services." -ForegroundColor "Green"

az functionapp config appsettings set `
    --name $ModelAppName `
    --resource-group $modelResourceGroupName `
    --settings "TrainingKey=$cog_services_training_key"

Write-Host "Creating app config setting: PredictionKey for cognitive services." -ForegroundColor "Green"

$accountName = $ModelAppName + "Prediction"

$cog_services_prediction_key = `
  (get-AzureRmCognitiveServicesAccountKey `
    -resourceGroupName $modelResourceGroupName `
    -AccountName $accountName).Key1

az functionapp config appsettings set `
    --name $ModelAppName `
    --resource-group $modelResourceGroupName `
    --settings "PredictionKey=$cog_services_prediction_key"

Write-Host "Creating app config setting: ResourceID for cognitive services.  This can be found under the Prediction resource on the HOME PAGE configuration settings of your cog services account https://www.customvision.ai/projects#/settings" -ForegroundColor "Green"

$subscription_id = (Get-AzureRmSubscription -SubscriptionName Thaugen-semisupervised-vision-closed-loop-solution).Id
$resource_id = "/subscriptions/" + $subscription_id + "/resourceGroups/" + $modelResourceGroupName + "/providers/Microsoft.CognitiveServices/accounts/" + $accountName

az functionapp config appsettings set `
    --name $ModelAppName `
    --resource-group $modelResourceGroupName `
    --settings "ResourceID=$resource_id"

Write-Host "Creating app config setting: ClientEndpoint for cognitive services." -ForegroundColor "Green"

az functionapp config appsettings set `
    --name $ModelAppName `
    --resource-group $modelResourceGroupName `
    --settings "ClientEndpoint=https://$modelCogServicesLocation.api.cognitive.microsoft.com/"
