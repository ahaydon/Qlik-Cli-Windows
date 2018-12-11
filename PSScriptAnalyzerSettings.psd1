@{
  Severity = @('Error', 'Warning')
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
