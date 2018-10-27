$roleDefinitions = Get-AzureRmRoleDefinition

foreach ($roleDefinition in $roleDefinitions){
    "####"
    $roleDefinition.Name
    $ResourceTypeAr = @()
    forEach ($action in $roleDefinition.actions){
        $ResourceTypeAr += $action.Split("/")[0]
    }
    $ResourceTypeAr | Group-Object | Sort-Object -Property Count -Descending
}

