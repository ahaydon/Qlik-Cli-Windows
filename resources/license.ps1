function Get-QlikAccessTypeInfo {
    PROCESS {
        return Invoke-QlikGet "/qrs/license/accesstypeinfo"
    }
}

function Get-QlikAnalyzerAccessType {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/license/analyzerAccessType"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}
Set-Alias -Name Get-QlikAnalyserAccessType -Value Get-QlikAnalyzerAccessType

function Get-QlikLicense {
    PROCESS {
        return Invoke-QlikGet "/qrs/license"
    }
}

function Get-QlikLicenseAudit {
    [CmdletBinding()]
    param (
        [string]$resourceType,
        [string]$resourceFilter,
        [string]$userFilter,
        [string]$environmentAttributes,
        [int]$userSkip,
        [int]$userTake,
        [int]$resourceSkip,
        [int]$resourceTake,
        [switch]$includeNonGrantingRules,
        [parameter(ValueFromPipelinebyPropertyName = $true)]
        [alias("id")]
        [string]$resourceId,
        [switch]$raw
    )
    PROCESS {
        $params = @{
            resourceType = $resourceType;
            resourceFilter = $resourceFilter;
            userFilter = $userFilter;
            environmentAttributes = $environmentAttributes;
            userSkip = $userSkip;
            userTake = $userTake;
            resourceSkip = $resourceSkip;
            resourceTake = $resourceTake;
        }
        If ( $includeNonGrantingRules ) { $params.includeNonGrantingRules = $true }
        If ( $resourceId ) { $params.resourceFilter = "id eq $resourceId" }
        $json = $params | ConvertTo-Json -Compress -Depth 10
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikPost "/qrs/systemrule/license/audit" $json
    }
}

function Get-QlikLoginAccessType {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/license/loginAccessType"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function Get-QlikProfessionalAccessType {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/license/professionalaccesstype"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function Get-QlikUserAccessType {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/license/useraccesstype"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function New-QlikProfessionalAccessGroup {
    [CmdletBinding()]
    param (
        [string]$name
    )

    PROCESS {
        $json = (@{
                name = $name
            } | ConvertTo-Json -Compress -Depth 10)

        return Invoke-QlikPost "/qrs/License/ProfessionalAccessGroup" $json
    }
}

function New-QlikUserAccessGroup {
    [CmdletBinding()]
    param (
        [string]$name
    )

    PROCESS {
        $json = (@{
                name = $name
            } | ConvertTo-Json -Compress -Depth 10)

        return Invoke-QlikPost "/qrs/License/UserAccessGroup" $json
    }
}

function Remove-QlikAnalyzerAccessType {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete -path "/qrs/license/analyzeraccesstype/$id"
    }
}
Set-Alias -Name Remove-QlikAnalyserAccessType -Value Remove-QlikAnalyzerAccessType

function Remove-QlikProfessionalAccessType {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete -path "/qrs/license/professionalaccesstype/$id"
    }
}

function Remove-QlikUserAccessType {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )
    PROCESS {
        return Invoke-QlikDelete -path "/qrs/license/useraccesstype/$id"
    }
}

function Set-QlikLicense {
    [CmdletBinding(DefaultParameterSetName = 'Serial')]
    param
    (
        [Parameter(ParameterSetName = 'Serial',
            Mandatory = $true,
            Position = 0)]
        [string]$serial,
        [Parameter(ParameterSetName = 'Serial',
            Mandatory = $true,
            Position = 1)]
        [string]$control,
        [Parameter(ParameterSetName = 'Key',
            Mandatory = $true,
            Position = 0)]
        [string]$key,
        [Parameter(Mandatory = $true,
            Position = 2)]
        [string]$name,
        [Parameter(Mandatory = $true,
            Position = 3)]
        [Alias('org')]
        [string]$organization,
        [Parameter(ParameterSetName = 'Serial',
            Mandatory = $false,
            Position = 4)]
        [string]$lef
    )

    PROCESS {
        Write-Verbose "Type: $($PSCmdlet.ParameterSetName)"
        $BaseURL = "/qrs/license"
        $CurrentQlikLicense = Invoke-QlikGet $BaseURL

        #Create the License Object we will pass to the API
        $QlikLicense = @{
            name = $name;
            organization = $organization;
        }

        if ($CurrentQlikLicense -eq "null") {
            Write-Verbose "QlikLicense = Null"
            $Process = "Post"
        }
        else {
            Write-Verbose "QlikLicense != Null"
            $Process = "Put"
            #Check for Key -> Serial downgrade
            if ($CurrentQlikLicense.key -ne "" -and $PSCmdlet.ParameterSetName -eq "Serial") { $Process = "downgrade" }

            #Update the License object with the Current License ID
            $QlikLicense.id = $CurrentQlikLicense.id
            $QlikLicense.modifiedDate = Get-Date -UFormat '+%Y-%m-%dT%H:%M:%S.000Z'
            $BaseURL = "$($BaseURL)/$($CurrentQlikLicense.id)"
        }

        switch ($PSCmdlet.ParameterSetName) {
            Key {
                $resourceURL = $BaseURL
                $QlikLicense.key = $key;
            }
            Serial {
                $resourceURL = "$($BaseURL)?control=$control"
                $QlikLicense.serial = $serial;
                $QlikLicense.lef = $lef;
            }
        }
        $json = $QlikLicense | ConvertTo-Json -Depth 10

        switch ($Process) {
            Post { $result = Invoke-QlikPost $resourceURL $json }
            Put { $result = Invoke-QlikPut $resourceURL $json }
            Downgrade { Write-Warning -Message "Qlik Sense APIs do NOT have a supported method for downgrading from a Signed License"; }
            Default { }
        }
    }
    END {
        return $result
    }
}
