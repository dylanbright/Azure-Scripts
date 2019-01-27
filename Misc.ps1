param(

    [ValidateScript({
        If ($_.ContainsValue("test")) {
            $_
            #Throw "$_ values must be test"
            $true
        } Else {$True}
    })][System.Collections.Hashtable]$ADNameAndTypeHash
)

$ADNameAndTypeHash.ContainsValue("test")
$ADNameAndTypeHash