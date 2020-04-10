@{
    Severity = @('Error', 'Warning', 'ParseError')
    ExcludeRules = @(
        'PSUseToExportFieldsInManifest',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
