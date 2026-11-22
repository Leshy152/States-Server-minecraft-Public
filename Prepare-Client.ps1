$ErrorActionPreference = 'Stop'
$mod = 'morediscs-1.21.1-neoforge-35.2.jar'
$mods = Join-Path $PSScriptRoot 'minecraft\mods'
$destination = Join-Path $mods $mod
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'MODS-SHA256.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$expected = $manifest.PSObject.Properties[$mod].Value
if ($expected -notmatch '^[a-fA-F0-9]{64}$') { throw "Missing SHA-256 for $mod." }

if ((Test-Path -LiteralPath $destination -PathType Leaf) -and
    (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -eq $expected) {
    Write-Host 'Client files are ready.'
    exit 0
}

$temporary = Join-Path $mods ('.morediscs-' + [Guid]::NewGuid().ToString('N') + '.tmp')
$parts = Join-Path $PSScriptRoot 'parts'
try {
    $output = [IO.File]::Open($temporary, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        foreach ($name in @('morediscs.part01','morediscs.part02','morediscs.part03')) {
            $file = Join-Path $parts $name
            if (-not [IO.File]::Exists($file)) { throw "Missing $name. Download the whole folder from the repository." }
            $partStream = [IO.File]::OpenRead($file)
            try { $partStream.CopyTo($output) } finally { $partStream.Dispose() }
        }
    } finally {
        $output.Dispose()
    }
    if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash -ne $expected) {
        throw "SHA-256 mismatch for $mod. Download the folder again."
    }
    if ([IO.File]::Exists($destination)) {
        [IO.File]::Replace($temporary, $destination, [NullString]::Value)
    } else {
        [IO.File]::Move($temporary, $destination)
    }
} finally {
    if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
}
Write-Host 'Client files are ready.'
