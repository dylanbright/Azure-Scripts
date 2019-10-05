Search-AzureRmGraph -Query "where type =~ 'Microsoft.RecoveryServices/vaults'"
#Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems

Search-AzureRmGraph -Query "where type =~ 'Microsoft.RecoveryServices/vaults/backupFabrics'"

Search-AzureRmGraph -Query "where type contains 'Microsoft' | distinct type"

Search-AzureRmGraph -Query "where type contains 'Microsoft.Network/virtualNetworks'"

Search-AzureRmGraph -Query "where type contains 'Microsoft' | distinct resourceGroup | count"
Search-AzureRmGraph -Query "where type contains 'Microsoft.Network/publicIPAddresses'" -Skip 2000
Search-AzureRmGraph -Query "where type contains 'Microsoft.Network/publicIPAddresses'" -First 5000 | select -ExpandProperty properties | select ipAddress,ipConfiguration | where {$_.ipAddress -like '52.166.*' }

Search-AzureRmGraph -Query "where type contains 'microsoft.web/sites'" -First 5000 | ? {$_.name -like "*ctefiling*"} | select resourceID

Search-AzureRmGraph -Query "where type contains 'Microsoft.web' | distinct type"

Search-AzureRMGraph -Query "where type =~ 'Microsoft.Resources/subscriptions'"

Search-AzureRMGraph -Query "where type =~ 'Microsoft.Resources/subscriptions' | summarize count()"
Search-AzureRmGraph -Query "where type contains 'microsoft.network/publicipaddresses' and properties.ipAddress startswith '104.44'"

$v = Search-AzureRmGraph -Query "where type contains 'microsoft.compute' and subscriptionId == '22877867-2cac-471f-9476-17d1eea5469f'"


$results = (Search-AzureRmGraph -Query "where type == 'microsoft.compute/virtualmachines' 
and subscriptionId == '22877867-2cac-471f-9476-17d1eea5469f'
|project name, resourceGroup, type" -First 500) 

$xdpsheet = import-csv C:\temp\xdprgs.csv
$xdpsheet | {$_}

$results | export-csv c:\temp\xdpgraph.csv

Search-AzureRmGraph -Query "where type contains 'microsoft.network/publicipaddresses' and properties.ipAddress contains '168.62.'"

Search-AzureRmGraph -Query 
directoryRole

Search-AzureRmGraph -Query "where type contains 'role' | distinct type"

function ConcatenatedGraphQuery {
    param ($query,$increment)
    $output = $null
    $page = $null
    #first query
    $output = Search-AzureRmGraph -Query $query -first $increment
    #successive queries
    do {
        $page = Search-AzureRmGraph -Query $query -first $increment -Skip $output.count
        $output += $page
    } while ($page)
    return $output
}

$out = ConcatenatedGraphQuery -query "where type contains 'microsoft.network/publicipaddresses'" -increment 500

Search-AzureRmGraph -Query "where type contains 'microsoft' | summarize count () by type" -First 200 #you need -first to make it get more than 100 things

search-azurermgraph ("where id == '" + $id + "'")

Search-AzureRmGraph -Query "where type contains 'microsoft.network/virtualnetwork'" -first 1
Search-AzureRmGraph -Query "where id == '/subscriptions/f8f6b890-69b9-4346-9af7-d7be7e75cbd6/resourceGroups/PZI-GXEU-TS-RGP-PAFW-P001/providers/Microsoft.Network/networkInterfaces/gx-zwetsfwxpla001-n1-eth3/ipConfigurations/ipconfig-dmz'"

ConcatenatedGraphQuery -query "where type contains 'microsoft' | summarize count () by type" -increment 200

$out = Search-AzureRmGraph -Query "where type contains 'microsoft' | summarize count () by type" 
$out | Export-csv -NoTypeInformation -Path 'c:\temp\output.csv'