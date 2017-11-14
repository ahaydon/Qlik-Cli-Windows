function Get-QlikRule {
  [CmdletBinding()]
  param (
    [parameter(Position=0)]
    [string]$id,
    [string]$filter,
    [switch]$full,
    [switch]$raw
  )

  PROCESS {
    $path = "/qrs/systemrule"
    If( $id ) { $path += "/$id" }
    If( $full ) { $path += "/full" }
    If( $raw ) { $rawOutput = $true }
    return Invoke-QlikGet $path $filter
  }
}

function New-QlikRule {
  [CmdletBinding()]
  param (
    [parameter(ValueFromPipeline=$true)]
    [PSObject]$object,

    [string]$name,

    [ValidateSet("License","Security","Sync")]
    [string]$category,

    [string]$rule,

    [alias("filter")]
    [string]$resourceFilter,

    [ValidateSet("hub","qmc","both")]
    [alias("context")]
    [string]$rulecontext = "both",

    [int]$actions,
    [string]$comment,
    [switch]$disabled
  )

  PROCESS {
    If( $object ) {
      $json = $object | ConvertTo-Json -Compress -Depth 10
    } else {
      # category is case-sensitive so convert to Title Case
      $category = (Get-Culture).TextInfo.ToTitleCase($category.ToLower())
      switch ($rulecontext)
      {
        both { $context = 0 }
        hub { $context = 1 }
        qmc { $context = 2 }
      }

      $json = (@{
        category = $category;
        type = "Custom";
        rule = $rule;
        name = $name;
        resourceFilter = $resourceFilter;
        actions = $actions;
        comment = $comment;
        disabled = $disabled.IsPresent;
        ruleContext = $context;
        tags = @();
        schemaPath = "SystemRule"
      } | ConvertTo-Json -Compress)
    }

    return Invoke-QlikPost "/qrs/systemrule" $json
  }
}

function Remove-QlikRule {
  [CmdletBinding()]
  param (
    [parameter(Position=0,ValueFromPipelinebyPropertyName=$true)]
    [string]$id
  )

  PROCESS {
    return Invoke-QlikDelete "/qrs/systemrule/$id"
  }
}

function Update-QlikRule {
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True,Position=0)]
    [string]$id,
    [string]$name,

    [ValidateSet("License","Security","Sync")]
    [string]$category,

    [string]$rule,

    [alias("filter")]
    [string]$resourceFilter,

    [ValidateSet("hub","qmc","both")]
    [alias("context")]
    [string]$rulecontext,

    [int]$actions,
    [string]$comment,
    [switch]$disabled
  )

  PROCESS {
    switch ($rulecontext)
    {
      both { $context = 0 }
      hub { $context = 1 }
      qmc { $context = 2 }
    }

    $systemrule = Get-QlikRule $id -raw
    If( $name ) { $systemrule.name = $name }
    If( $rule ) { $systemrule.rule = $rule }
    If( $resourceFilter ) { $systemrule.resourceFilter = $resourceFilter }
    If( $category ) { $systemrule.category = $category }
    If( $rulecontext ) { $systemrule.rulecontext = $context }
    If( $actions ) { $systemrule.actions = $actions }
    If( $comment ) { $systemrule.comment = $comment }
    If( $psBoundParameters.ContainsKey("disabled") ) { $systemrule.disabled = $disabled.IsPresent }

    $json = $systemrule | ConvertTo-Json -Compress -Depth 10
    return Invoke-QlikPut "/qrs/systemrule/$id" $json
  }
}
