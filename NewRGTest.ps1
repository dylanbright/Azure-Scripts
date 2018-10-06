param ($rgname)

New-AzureRmResourceGroup -Name $rgname -location eastus -ErrorAction SilentlyContinue
sleep 10
