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
    $repoRoot = [System.IO.Path]::GetFullPath($cwd).TrimEnd('\\', '/')
} catch {
    exit 0
}

function Get-StringValues {
    param([object]$Value)

    if ($null -eq $Value) {
        return
    }

    if ($Value -is [string]) {
        $Value
        return
    }

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($entryValue in $Value.Values) {
            Get-StringValues -Value $entryValue
        }

        return
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        foreach ($item in $Value) {
            Get-StringValues -Value $item
        }

        return
    }

    if ($Value -is [psobject]) {
        foreach ($property in $Value.PSObject.Properties) {
            Get-StringValues -Value $property.Value
        }
    }
}

function Test-PathLikeString {
    param([string]$Candidate)

    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        return $false
    }

    if ($Candidate -match '^[a-zA-Z][a-zA-Z0-9+.-]*://') {
        return $false
    }

    return $Candidate.Contains('\\') -or $Candidate.Contains('/') -or [System.IO.Path]::IsPathRooted($Candidate)
}

function Resolve-CandidatePath {
    param(
        [string]$Candidate,
        [string]$BasePath
    )

    try {
        if ([System.IO.Path]::IsPathRooted($Candidate)) {
            return [System.IO.Path]::GetFullPath($Candidate)
        }

        return [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($BasePath, $Candidate))
    } catch {
        return $null
    }
}

$repoRootWithSeparator = $repoRoot + [System.IO.Path]::DirectorySeparatorChar
$offendingPaths = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)

foreach ($candidate in Get-StringValues -Value $payload.tool_input) {
    if (-not (Test-PathLikeString -Candidate $candidate)) {
        continue
    }

    $resolvedPath = Resolve-CandidatePath -Candidate $candidate -BasePath $repoRoot
    if ([string]::IsNullOrWhiteSpace($resolvedPath)) {
        continue
    }

    $normalizedResolvedPath = $resolvedPath.TrimEnd('\\', '/')
    $isInsideRepo =
        $normalizedResolvedPath.Equals($repoRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
        $normalizedResolvedPath.StartsWith($repoRootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)

    if (-not $isInsideRepo) {
        $null = $offendingPaths.Add("'$candidate' -> '$resolvedPath'")
    }
}

if ($offendingPaths.Count -gt 0) {
    @{
        permissionDecision = 'deny'
        permissionDecisionReason = "Path guard denied tool use because these paths resolve outside the repository root '$repoRoot': $([string]::Join('; ', $offendingPaths))"
    } | ConvertTo-Json -Compress
}
