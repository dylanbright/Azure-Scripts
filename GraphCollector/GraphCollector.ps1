Enable-AzureRmAlias

#Functions
#These first two we got from https://tjaddison.com/2018/08/26/Getting-started-with-Log-Analytics-and-PowerShell-logging


Function Get-LogAnalyticsSignature {
    [cmdletbinding()]
    Param (
        $customerId,
        $sharedKey,
        $date,
        $contentLength,
        $method,
        $contentType,
        $resource
    )
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}

Function Export-LogAnalytics {
    [cmdletbinding()]
    Param(
        $customerId,
        $sharedKey,
        $object,
        $logType,
        $TimeStampField
    )
    $bodyAsJson = ConvertTo-Json $object
    $body = [System.Text.Encoding]::UTF8.GetBytes($bodyAsJson)

    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length

    $signatureArguments = @{
        CustomerId = $customerId
        SharedKey = $sharedKey
        Date = $rfc1123date
        ContentLength = $contentLength
        Method = $method
        ContentType = $contentType
        Resource = $resource
    }

    $signature = Get-LogAnalyticsSignature @signatureArguments
    
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    return $response.StatusCode
}

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

function PrepLogAnalyticsObject{
    #Flattens an object, such that it is only simple property and value pairs.
    #for use with log analytics custom data.
    param ($object) #can be an object or array of objects.
    foreach ($objectMember in $object){
        foreach ($property in $objectMember.PsObject.properties) {
            $property
        }


    }

}

Function Flatten-Object {                                       # Version 00.02.12, by iRon
    [CmdletBinding()]Param (
        [Parameter(ValueFromPipeLine = $True)][Object[]]$Objects,
        [String]$Separator = ".", [ValidateSet("", 0, 1)]$Base = 1, [Int]$Depth = 5, [Int]$Uncut = 1,
        [String[]]$ToString = ([String], [DateTime], [TimeSpan]), [String[]]$Path = @()
    )
    $PipeLine = $Input | ForEach {$_}; If ($PipeLine) {$Objects = $PipeLine}
    If (@(Get-PSCallStack)[1].Command -eq $MyInvocation.MyCommand.Name -or @(Get-PSCallStack)[1].Command -eq "<position>") {
        $Object = @($Objects)[0]; $Iterate = New-Object System.Collections.Specialized.OrderedDictionary
        If ($ToString | Where {$Object -is $_}) {$Object = $Object.ToString()}
        ElseIf ($Depth) {$Depth--
            If ($Object.GetEnumerator.OverloadDefinitions -match "[\W]IDictionaryEnumerator[\W]") {
                $Iterate = $Object
            } ElseIf ($Object.GetEnumerator.OverloadDefinitions -match "[\W]IEnumerator[\W]") {
                $Object.GetEnumerator() | ForEach -Begin {$i = $Base} {$Iterate.($i) = $_; $i += 1}
            } Else {
                $Names = If ($Uncut) {$Uncut--} Else {$Object.PSStandardMembers.DefaultDisplayPropertySet.ReferencedPropertyNames}
                If (!$Names) {$Names = $Object.PSObject.Properties | Where {$_.IsGettable} | Select -Expand Name}
                If ($Names) {$Names | ForEach {$Iterate.$_ = $Object.$_}}
            }
        }
        If (@($Iterate.Keys).Count) {
            $Iterate.Keys | ForEach {
                Flatten-Object @(,$Iterate.$_) $Separator $Base $Depth $Uncut $ToString ($Path + $_)
            }
        }  Else {$Property.(($Path | Where {$_}) -Join $Separator) = $Object}
    } ElseIf ($Objects -ne $Null) {
        @($Objects) | ForEach -Begin {$Output = @(); $Names = @()} {
            New-Variable -Force -Option AllScope -Name Property -Value (New-Object System.Collections.Specialized.OrderedDictionary)
            Flatten-Object @(,$_) $Separator $Base $Depth $Uncut $ToString $Path
            $Output += New-Object PSObject -Property $Property
            $Names += $Output[-1].PSObject.Properties | Select -Expand Name
        }
        $Output | Select ([String[]]($Names | Select -Unique))
    }
}

$resourceGroupName = 'dcb-graph-collector'
$workspaceName = 'graph-test-la-01'

$sharedkey = (Get-AzureRmOperationalInsightsWorkspaceSharedKeys -ResourceGroupName $resourceGroupName -Name $workspaceName).PrimarySharedKey
$customerId = (Get-AzureRmOperationalInsightsWorkspace -ResourceGroupName $resourceGroupName -Name $workspaceName).CustomerId.guid

$output = ConcatenatedGraphQuery -query "where type == 'microsoft.network/virtualnetworks'" -increment 100

Export-LogAnalytics -customerId $customerId -sharedKey $sharedkey -object $output -logType 'Inventory' -TimeStampField (get-date)

Export-LogAnalytics -customerId $customerId -sharedKey $sharedkey -object (Get-Process) -logType 'ProcTest' -TimeStampField (get-date)

New-AzOperationalInsightsCustomLogDataSource -WorkspaceName $workspaceName -Name 'Inventory3' -CustomLogRawJson (Flatten-object $output | ConvertTo-Json) -ResourceGroupName $resourceGroupName 

New-AzOperationalInsightsCustomLogDataSource -WorkspaceName $workspaceName -Name 'Inventory3' -CustomLogRawJson $json -ResourceGroupName $resourceGroupName

$json = '{
    "team.showWelcomeMessage": false,
    "window.zoomLevel": 0,
    "terminal.integrated.shell.windows": "C:\\Program Files\\PowerShell\\6\\pwsh.exe",
    "powershell.codeFormatting.useCorrectCasing": true,
    "powershell.powerShellExePath": "C:\\\\Program Files\\\\PowerShell\\\\6\\\\pwsh.exe"
}'