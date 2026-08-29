BeforeAll {
    $scriptDirectory = Join-Path $PSScriptRoot '..' 'scripts'
    $scriptFiles = @(Get-ChildItem $scriptDirectory -Filter '*.ps1' -File)
}

Describe 'Repository safety contract' {
    It 'ships the documented twelve scripts' {
        $scriptFiles.Count | Should -Be 12
    }

    It 'includes comment-based help in every script' {
        foreach ($scriptFile in $scriptFiles) {
            $help = Get-Help $scriptFile.FullName -Full
            $help.Synopsis | Should -Not -BeNullOrEmpty -Because $scriptFile.Name
            $help.Examples.Example.Count | Should -BeGreaterThan 0 -Because $scriptFile.Name
        }
    }

    It 'contains no parser errors' {
        foreach ($scriptFile in $scriptFiles) {
            $tokens = $null
            $errors = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile($scriptFile.FullName, [ref]$tokens, [ref]$errors)
            $errors | Should -BeNullOrEmpty -Because $scriptFile.Name
        }
    }

    It 'does not authenticate on the operator behalf' {
        foreach ($scriptFile in $scriptFiles) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptFile.FullName, [ref]$tokens, [ref]$errors)
            $commands = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true) |
                ForEach-Object { $_.GetCommandName() } |
                Where-Object { $_ }
            $commands | Should -Not -Contain 'Connect-MgGraph' -Because $scriptFile.Name
            $commands | Should -Not -Contain 'Connect-ExchangeOnline' -Because $scriptFile.Name
            $commands | Should -Not -Contain 'Connect-MicrosoftTeams' -Because $scriptFile.Name
        }
    }

    It 'does not expose password, token, secret, or credential parameters' {
        foreach ($scriptFile in $scriptFiles) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptFile.FullName, [ref]$tokens, [ref]$errors)
            $parameterNames = @($ast.ParamBlock.Parameters.Name.VariablePath.UserPath)
            $parameterNames -join ',' | Should -Not -Match '(?i)password|token|secret|credential|api.?key' -Because $scriptFile.Name
        }
    }
}
