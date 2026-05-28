$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) {
    exit 0
}

try {
    $payload = $rawInput | ConvertFrom-Json -Depth 100
} catch {
    exit 0
}

$cwd = [string]$payload.cwd
if ([string]::IsNullOrWhiteSpace($cwd)) {
    exit 0
}

try {
    Set-Location -LiteralPath $cwd
    $repoRoot = (Get-Location).Path
} catch {
    exit 0
}

$frontendPath = Join-Path $repoRoot 'src\RecipeHub.Web'
$issues = New-Object System.Collections.Generic.List[object]

function Format-CommandOutput {
    param([string]$Output)

    if ([string]::IsNullOrWhiteSpace($Output)) {
        return 'No output captured.'
    }

    $lines = $Output -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($lines.Count -eq 0) {
        return 'No output captured.'
    }

    return ($lines | Select-Object -First 20) -join [System.Environment]::NewLine
}

function Add-Issue {
    param(
        [string]$Title,
        [string]$Fix,
        [string]$Output
    )

    $issues.Add([pscustomobject]@{
        Title = $Title
        Fix = $Fix
        Output = Format-CommandOutput -Output $Output
    }) | Out-Null
}

function Test-MissingToolOutput {
    param([string]$Output)

    if ([string]::IsNullOrWhiteSpace($Output)) {
        return $false
    }

    $normalizedOutput = $Output.ToLowerInvariant()
    $missingToolMarkers = @(
        'could not execute because the specified command or file was not found',
        'could not determine executable to run',
        'not recognized as the name of a cmdlet',
        'no such file or directory',
        'command not found'
    )

    foreach ($marker in $missingToolMarkers) {
        if ($normalizedOutput.Contains($marker)) {
            return $true
        }
    }

    return $false
}

function Test-LocalNpxTool {
    param([string]$ToolName)

    if (-not (Test-Path -LiteralPath $frontendPath)) {
        return $false
    }

    $candidates = @(
        (Join-Path $frontendPath "node_modules\.bin\$ToolName.cmd"),
        (Join-Path $frontendPath "node_modules\.bin\$ToolName.ps1"),
        (Join-Path $frontendPath "node_modules\.bin\$ToolName")
    )

    return [bool]($candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1)
}

function Invoke-ExternalCheck {
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [string]$Title,
        [string]$Fix,
        [switch]$RequireFrontendTool,
        [string]$FrontendToolName
    )

    try {
        if (-not (Get-Command $Executable -ErrorAction SilentlyContinue)) {
            return
        }

        if ($RequireFrontendTool -and -not (Test-LocalNpxTool -ToolName $FrontendToolName)) {
            return
        }

        $commandOutput = & $Executable @Arguments 2>&1 | ForEach-Object { $_.ToString() }
        $exitCode = $LASTEXITCODE
        $formattedOutput = $commandOutput -join [System.Environment]::NewLine

        if ($exitCode -ne 0 -and -not (Test-MissingToolOutput -Output $formattedOutput)) {
            Add-Issue -Title $Title -Fix $Fix -Output $formattedOutput
        }
    } catch {
        return
    }
}

Invoke-ExternalCheck -Executable 'dotnet' -Arguments @('format', '--verify-no-changes') -Title 'dotnet format' -Fix 'Run `dotnet format` from the repo root to apply required formatting and analyzer fixes, then re-run the checks.'
Invoke-ExternalCheck -Executable 'npx' -Arguments @('--no-install', '--prefix', 'src/RecipeHub.Web', 'eslint', 'src/RecipeHub.Web/src', '--ext', '.ts,.tsx', '--max-warnings', '0') -Title 'ESLint' -Fix 'Run `npx --no-install --prefix src/RecipeHub.Web eslint "src/RecipeHub.Web/src" --ext .ts,.tsx --max-warnings 0 --fix` from the repo root, then resolve any remaining lint errors.' -RequireFrontendTool -FrontendToolName 'eslint'
Invoke-ExternalCheck -Executable 'npx' -Arguments @('--no-install', '--prefix', 'src/RecipeHub.Web', 'prettier', '--check', 'src/RecipeHub.Web/src') -Title 'Prettier' -Fix 'Run `npx --no-install --prefix src/RecipeHub.Web prettier --write src/RecipeHub.Web/src` from the repo root to apply formatting, then re-run the checks.' -RequireFrontendTool -FrontendToolName 'prettier'

if ($issues.Count -gt 0) {
    $reasonLines = @(
        '🚫 Lint/format check failed. Fix these issues:',
        ''
    )

    for ($index = 0; $index -lt $issues.Count; $index++) {
        $issue = $issues[$index]
        $reasonLines += "$($index + 1). $($issue.Title): $($issue.Fix)"

        foreach ($line in ($issue.Output -split "`r?`n")) {
            $reasonLines += "   $line"
        }

        if ($index -lt $issues.Count - 1) {
            $reasonLines += ''
        }
    }

    @{
        decision = 'block'
        reason = ($reasonLines -join [System.Environment]::NewLine).TrimEnd()
    } | ConvertTo-Json -Compress
}
