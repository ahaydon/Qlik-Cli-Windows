@{
    Severity = @('Error', 'Warning', 'ParseError', 'Information')
    ExcludeRules = @(
        'PSUseToExportFieldsInManifest',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
