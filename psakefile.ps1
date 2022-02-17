[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Justification = "For testing purposes only")]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Justification = "For testing purposes only")]
param()

$InformationPreference = 'Continue'

Properties {
    $project_name = 'Qlik-Cli'
    $output = "output/$project_name"
    $winrm_port = 55986
    $pkg_path = './output'
    $qlik_context = 'ManagementAccess'
    $qlik_user = 'INTERNAL\sa_api'
}

Task PSRemote {
    if (Get-Command -Name Disable-WSManCertVerification -ErrorAction Ignore) {
        Disable-WSManCertVerification -All
    }

    $script:instances = @()
    $script:instance_port = @{ }
    $instance_files = Get-ChildItem -Path ./.kitchen/ -Filter *.yml
    foreach ($file in $instance_files) {
        if ($Matches = Select-String -Path $file -Pattern "^port: '(\d+)'") {
            [int]$port = $Matches.Matches[0].Groups[1].Value
            Write-Debug "Add port: $($file.BaseName) $($port + 1)"
            $instance_port.Add($file.BaseName, $port + 1)
        }
    }

    foreach ($instance in $instance_port.Keys) {
        $session_name = "kitchen_$instance"
        if ($session = Get-PSSession -Name $session_name -ErrorAction SilentlyContinue) {
            if ($session.State -ne 'Opened') {
                Remove-PSSession -Session $session
            }
            else {
                $script:instances += $session
                Continue
            }
        }

        $password = ConvertTo-SecureString -String 'vagrant' -AsPlainText -Force
        $vagrant_cred = New-Object System.Management.Automation.PSCredential('vagrant', $password)
        $so = New-PSSessionOption -SkipCACheck -SkipCNCheck
        Write-Information "$instance`: $($instance_port[$instance])" -InformationAction Continue
        $session = New-PSSession `
            -Name $session_name `
            -ComputerName localhost `
            -Credential $vagrant_cred `
            -EnableNetworkAccess `
            -Port $instance_port[$instance] `
            -UseSSL `
            -SessionOption $so `
            -Authentication Basic
        $script:instances += $session
        Remove-Variable -Name $session_name -Scope Global -ErrorAction SilentlyContinue
        Set-Variable -Name $session_name -Value $session -Scope Global
    }
}

Task ExportCert -Depends PSRemote, Deploy {
    $sessions = $script:instances
    foreach ($session in $sessions) {
        Write-Verbose $session.Name.SubString(0, 7) -Verbose
        if ($session.Name.SubString(0, 7) -eq 'kitchen') {
            $certPath = "./.kitchen/kitchen-vagrant/$($session.Name.SubString(8))/client.pfx"
        }
        else {
            $certPath = "./.vagrant/machines/$($session.Name.SubString(8))/client.pfx"
        }
        if (Test-Path $certPath) {
            Write-Information "$($session.Name) [Skipped] exists"
            continue
        }
        $IsCentral = Invoke-Command -Session $session {
            $hostname = [System.Net.Dns]::GetHostName()
            Import-Module Qlik-Cli
            Get-QlikNode -filter "hostname eq '$hostname'" -full -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty IsCentral -First 1
        }
        if (! $IsCentral) {
            Write-Information "$($session.Name) [Skipped] not central node"
            continue
        }

        $result = Invoke-Command -Session $session -ArgumentList $session.Name {
            $password = ConvertTo-SecureString -String 'vagrant' -AsPlainText -Force
            $cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object Subject -eq 'CN=QlikClient'
            if ($cert) {
                Write-Information "$($args[0]): Exporting certificate"
                Export-PfxCertificate -cert $cert -FilePath "$env:TEMP\$($cert.Thumbprint).pfx" -password $password
            }
        }
        if ($result) {
            Write-Information "$($session.Name)"
            Copy-Item $result.FullName $certPath -FromSession $session
        }
        else {
            $result = Invoke-Command -Session $session -ErrorAction 'Ignore' -ArgumentList $session.Name {
                if ((Get-QlikNode local).IsCentral) {
                    Write-Verbose "$($args[0]): Generating certificate"
                    Export-QlikCertificate -machinename vagrant -includeSecretsKey -exportFormat Windows -certificatePassword $password
                }
            }
            if ($result) {
                Write-Information "$($session.Name)"
                Copy-Item `
                    -Path 'C:\ProgramData\Qlik\Sense\Repository\Exported Certificates\vagrant\client.pfx' `
                    -Destination $certPath `
                    -FromSession $session
            }
            else {
                Write-Information "$($session.Name) [Skipped]"
            }
        }
    }
}

Task ConnectQlik -Depends ExportCert {
    if (! $instance) {
        $instance = '.*'
    }
    Write-Verbose "Instance: $instance"
    if (! $script:instance_port) {
        $script:instance_port = @{ }
    }
    if ($qlikuser) {
        $qlik_user = $qlikuser
    }
    Write-Verbose "User: $qlik_user"
    if ($qlikcontext) {
        $qlik_context = $qlikcontext
    }
    Write-Verbose "Context: $qlik_context"
    $certPath = Get-ChildItem -Path .kitchen, .vagrant -Recurse -Filter '*.pfx' |
        Where-Object { $_.DirectoryName -match $instance } |
        Select-Object -First 1
    if (! $certPath) {
        break
    }
    $password = ConvertTo-SecureString -String 'vagrant' -AsPlainText -Force
    Write-Verbose "Cert: $($certPath.FullName)"
    $cert = Get-PfxCertificate `
        -FilePath $certPath.FullName `
        -Password $password
    Write-Verbose $cert.Thumbprint
    Write-Debug "Check port: $($certPath.Directory.Name)"
    $env:VAGRANT_CWD = $certPath.Directory.FullName
    $qrs_port = (& vagrant port --guest 4242)
    Write-Verbose "Port: $qrs_port"
    Write-Information "$($certPath.Directory.Name) $qrs_port [$qlik_user, $qlik_context]"
    Import-Module ./Qlik-Cli.psd1 -Force -Scope Global
    $cert | Connect-Qlik -Computername https://localhost:$qrs_port -TrustAllCerts -Username $qlik_user -Context $qlik_context
}

Task Clean {
    if (Test-Path $output) {
        Remove-Item $output -Force -Recurse
    }
}

Task Build -Depends Clean {
    $mod = Test-ModuleManifest -Path ./$project_name.psd1
    $manifest = Import-LocalizedData -FileName "$project_name.psd1"
    if ($null -eq $version) {
        $version = $mod.Version
    }
    Assert ($version -ne $null) 'version must not be null'

    $destinationRoot = New-Item -Path $output -ItemType Directory -Force
    $moduleVersion, $prerelease = $version -split '-'

    Get-Module Qlik-Cli | Remove-Module -Force
    Import-Module ./Qlik-Cli.psd1
    $mod = (Get-Module -Name Qlik-Cli)
    $functions = $mod.ExportedFunctions.Keys
    $nested = $mod.NestedModules.Path
    $files = @('./Qlik-Cli.psd1', $mod.Path) + $nested | Resolve-Path -Relative
    $files | ForEach-Object {
        $dest = Join-Path $destinationRoot $_
        New-Item -Path ($dest | Split-Path -Parent) -ItemType Directory -Force | Out-Null
        Copy-Item $_ $dest
    }
    $manifest = Join-Path $destinationRoot './Qlik-Cli.psd1'
    Update-ModuleManifest `
        -Path $manifest `
        -ModuleVersion $moduleVersion `
        -FunctionsToExport $functions `
        -NestedModules ($nested | Resolve-Path -Relative) `
        -Prerelease $prerelease
}

Task Package -Depends Build {
    if (!(Test-Path $pkg_path)) {
        New-Item -Path $pkg_path -ItemType Directory | Out-Null
    }

    $package = Join-Path $pkg_path "$project_name.zip"
    if (Test-Path $package) {
        Remove-Item $package
    }

    Compress-Archive -Path $output/* -DestinationPath $package
}

Task Deploy -Depend Package, PSRemote {
    $sessions = $script:instances
    foreach ($session in $sessions) {
        $localPath = (Join-Path $pkg_path "$project_name.zip" | Get-Item).FullName
        $remotePath = "C:\Users\vagrant\Documents\$project_name.zip"
        Copy-Item -Path $localPath -Destination $remotePath -ToSession $session
        Invoke-Command -Session $session {
            $module_path = "$env:ProgramFiles\WindowsPowerShell\Modules\$using:project_name"
            if (Test-Path $module_path) {
                Remove-Item $module_path -Recurse -Force
            }
            Expand-Archive $using:remotePath $module_path
        }
    }
}

Task UpdateDocs {
    Get-Module Qlik-Cli | Remove-Module -Force
    Import-Module ./Qlik-Cli.psd1 -Scope Global
    Update-MarkdownHelpModule -Path ./docs -RefreshModulePage -ModulePagePath ./docs/index.md -UpdateInputOutput -Force
}
