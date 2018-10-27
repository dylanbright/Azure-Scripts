param (
    $subscriptionName,
    $ResourceGroupName = "testwithvm",
    $ADNameAndTypeHash = @{"dylan"="user";"testgroup"="group"} #Hashtable of object names and types e.g. "dylan.bright@pwc.com" = "user"
    )  



class ResourceRBACRule {
    [string]$ResourceType
    [string]$ResourceFriendlyName
    [boolean]$IaaS
    [validateset("resourceGroup","resource")][string]$AssignmentLevel
    [string]$roleDefinitionName

    ResourceRBACRule(
        [string]$ResourceType,
        [string]$ResourceFriendlyName,
        [boolean]$IaaS = $false,
        [string]$AssignmentLevel,
        [string]$roleDefinitionName
    ){
        $this.ResourceType = $ResourceType
        $this.ResourceFriendlyName = [string]$ResourceFriendlyName
        $this.IaaS = $IaaS
        $this.AssignmentLevel = $AssignmentLevel
        $this.roleDefinitionName = $roleDefinitionName
    }

}

function get-AzureADObjectID ($ADObjectNames){
    $ADObjectIDs = @()
    ForEach ($h in $ADObjectNames.GetEnumerator()){
        switch ($h.value){
            #By getting the first result if an array is returned, we get as close to the exact name searched as possible.
            "group" {$ADObjectIDs += (Get-AzureRmADGroup -SearchString $h.Name)[0].Id }
            "user"  {$ADObjectIDs += (Get-AzureRmADUser -SearchString $h.Name)[0].Id } 
            "spn"   {$ADObjectIDs += (Get-AzureRmADServicePrincipal -SearchString $h.Name)[0].Id}
            "ID"    {$ADObjectIDs += $h.Name}
        }
    }
    return $ADObjectIDs
}

function New-RoleAssignmentForArrayOfObjects ($scope,$ObjectIDs,$roleDefinitionName){
    foreach ($ObjectID in $ObjectIDs){
        New-AzureRmRoleAssignment -Scope $scope -ObjectId $ObjectID -RoleDefinitionName $roleDefinitionName
    }
}

#Define Role Assignments Rules
$RBACRules = @()
$RBACRules += [ResourceRBACRule]::new("Microsoft.Web/serverfarms","AppServicePlan ",$false,"resourceGroup","Website Contributor") 
$RBACRules += [ResourceRBACRule]::new("Microsoft.Web/serverfarms","AppServicePlan ",$false,"resource","Web Plan Contributor") 

#Get the resource group and the resources in the resource group 
try {
    $resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName
}
catch {
    "Could not find resource group.  Exiting"
    exit    
}

$resources = Get-AzureRmResource -ResourceGroupName $ResourceGroupName
#Get the object IDs of the objects that are being assigned rights
$ADObjectIDs = $null #zero this out between runs.
$ADObjectIDs = Get-AzureADObjectID -ADObjectNames $ADNameAndTypeHash
#Before we start get the current role assignments
Get-AzureRmRoleAssignment -Scope $resourceGroup.ResourceId | ft Scope,DisplayName,RoleDefinitionName

foreach ($resource in $resources) {
    #Get any applicable rules to apply at the ResourceGroup level
    $ResourceGroupRBACRules = $RBACRules | Where-Object {$_.AssignmentLevel -eq "resourceGroup" -and $_.ResourceType -eq $resource.ResourceType}
    forEach ($ResourceGroupRBACRule in $ResourceGroupRBACRules){
        New-RoleAssignmentForArrayOfObjects -scope $resourceGroup.ResourceId -ObjectIDs $ADObjectIDs -roleDefinitionName $ResourceGroupRBACRule.roleDefinitionName
    }
    #Get any applicable rules to apply at the Resource level
    $ResourceRBACRules = $RBACRules | Where-Object {$_.AssignmentLevel -eq "resource" -and $_.ResourceType -eq $resource.ResourceType}
    forEach ($ResourceRBACRule in $ResourceRBACRules ){
        New-RoleAssignmentForArrayOfObjects -scope $resource.ResourceId -ObjectIDs $ADObjectIDs -roleDefinitionName $ResourceRBACRule.roleDefinitionName
    }
}
Get-AzureRmRoleAssignment -Scope $resourceGroup.ResourceId | ft Scope,DisplayName,RoleDefinitionName
$Transcript 