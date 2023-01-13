function Get-QlikAuditRule {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        [string]$resourceType,

        [string]$resourceFilter,
        [string]$userFilter,
        [string[]]$environmentAttributes,
        [int]$userSkip,
        [int]$userTake,
        [int]$resourceSkip,
        [int]$resourceTake,
        [switch]$includeNonGrantingRules
    )

    process {
        $audit = @{
            resourceType = $resourceType
            resourceFilter = $resourceFilter
            userFilter = $userFilter
            environmentAttributes = $environmentAttributes
            userSkip = $userSkip
            userTake = $userTake
            resourceSkip = $resourceSkip
            resourceTake = $resourceTake
            includeNonGrantingRules = $includeNonGrantingRules.IsPresent
        }

        $path = '/qrs/systemrule/security/audit'
        $json = $audit | ConvertTo-Json -Compress -Depth 10

        return Invoke-QlikPost $path $json
    }
}

function Get-QlikRule {
    [CmdletBinding()]
    param (
        [parameter(Position = 0)]
        [string]$id,
        [string]$filter,
        [switch]$full,
        [switch]$raw
    )

    PROCESS {
        $path = "/qrs/systemrule"
        If ( $id ) { $path += "/$id" }
        If ( $full ) { $path += "/full" }
        If ( $raw ) { $rawOutput = $true }
        return Invoke-QlikGet $path $filter
    }
}

function New-QlikRule {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline = $true)]
        [PSObject]$object,

        [string]$name,

        [ValidateSet("License", "Security", "Sync")]
        [string]$category,

        [string]$rule,

        [alias("filter")]
        [string]$resourceFilter,

        [ValidateSet("hub", "qmc", "both", "BothQlikSenseAndQMC", "QlikSenseOnly", "QMCOnly")]
        [alias("context")]
        [string]$rulecontext = "both",

        [int64]$actions,
        [string]$comment,
        [switch]$disabled,
        [string[]]$tags
    )

    PROCESS {
        If ( $object ) {
            $json = $object | ConvertTo-Json -Compress -Depth 10
        }
        else {
            $systemrule = @{
                type = "Custom";
                rule = $rule;
                name = $name;
                resourceFilter = $resourceFilter;
                actions = $actions;
                comment = $comment;
                disabled = $disabled.IsPresent;
                ruleContext = $context;
                schemaPath = "SystemRule"
            }

            if ($PSBoundParameters.ContainsKey("tags")) { $systemrule.tags = @(GetTags $tags) }
            # category is case-sensitive so convert to Title Case
            $systemrule.category = (Get-Culture).TextInfo.ToTitleCase($category.ToLower())

            $systemrule.ruleContext = switch ($rulecontext) {
                both { 0 }
                hub { 1 }
                qmc { 2 }
                default { $rulecontext }
            }

            $json = $systemrule | ConvertTo-Json -Compress -Depth 10
        }

        return Invoke-QlikPost "/qrs/systemrule" $json
    }
}

function Remove-QlikRule {
    [CmdletBinding()]
    param (
        [parameter(Position = 0, ValueFromPipelinebyPropertyName = $true)]
        [string]$id
    )

    PROCESS {
        return Invoke-QlikDelete "/qrs/systemrule/$id"
    }
}

function Update-QlikRule {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, Position = 0)]
        [string]$id,
        [string]$name,

        [ValidateSet("License", "Security", "Sync")]
        [string]$category,

        [string]$rule,

        [alias("filter")]
        [string]$resourceFilter,

        [ValidateSet("hub", "qmc", "both")]
        [alias("context")]
        [string]$rulecontext,

        [int64]$actions,
        [string]$comment,
        [switch]$disabled,

        [string[]]$tags
    )

    PROCESS {
        switch ($rulecontext) {
            both { $context = 0 }
            hub { $context = 1 }
            qmc { $context = 2 }
        }

        $systemrule = Get-QlikRule $id -raw
        If ( $name ) { $systemrule.name = $name }
        If ( $rule ) { $systemrule.rule = $rule }
        If ( $resourceFilter ) { $systemrule.resourceFilter = $resourceFilter }
        If ( $category ) { $systemrule.category = $category }
        If ( $rulecontext ) { $systemrule.rulecontext = $context }
        If ( $actions ) { $systemrule.actions = $actions }
        If ( $comment ) { $systemrule.comment = $comment }
        If ( $psBoundParameters.ContainsKey("disabled") ) { $systemrule.disabled = $disabled.IsPresent }
        if ($PSBoundParameters.ContainsKey("tags")) { $systemrule.tags = @(GetTags $tags $systemrule.tags) }

        $json = $systemrule | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPut "/qrs/systemrule/$id" $json
    }
}

function New-QlikLicenseRule {
    [CmdletBinding()]
    param
    (
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [ValidateSet('Analyzer', 'Professional')]
        [string]$Type,
        [string]$Rule,
        [string]$Comment,
        [switch]$Disabled,
        [string[]]$Tags
    )
    PROCESS	{
        $systemrule = @{
            type = "Custom";
            rule = $Rule;
            name = $Name;
            resourceFilter = "";
            actions = 1;
            comment = $Comment;
            disabled = $Disabled.IsPresent;
            ruleContext = 1;
            schemaPath = "SystemRule"
            category = "License"
        }
        if ($PSBoundParameters.ContainsKey("tags")) { $systemrule.tags = @(GetTags $tags) }
        $AccessGroup = @{
            name = $Name
        }
        $QSAccessGroup = Invoke-QlikPost -path "/qrs/license/$($type)accessgroup" -body $($AccessGroup | ConvertTo-Json)
        $systemrule.resourceFilter = "License.$($Type)AccessGroup_$($QSAccessGroup.id)"
        $json = $systemrule | ConvertTo-Json -Compress -Depth 10
        return Invoke-QlikPost -path "/qrs/systemrule" -body $json
    }
}
