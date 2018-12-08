@{
  Severity = @('Error')
  <#IncludeRules=@(
    'PSAvoidUsingPlainTextForPassword',
    'PSAvoidUsingConvertToSecureStringWithPlainText'
  )#>
  ExcludeRules = @(
    'PSUseToExportFieldsInManifest',
    'PSUseDeclaredVarsMoreThanAssignments',
    'PSUseShouldProcessForStateChangingFunctions'
  )
}
