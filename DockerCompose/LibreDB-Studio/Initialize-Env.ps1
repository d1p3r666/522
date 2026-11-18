$ErrorActionPreference = 'Stop'
$envPath = Join-Path $PSScriptRoot '.env'
if (Test-Path -LiteralPath $envPath) {
    Write-Host '.env already exists; keeping existing credentials.'
    return
}

function New-RandomSecret {
    $bytes = New-Object byte[] 48
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
        return [Convert]::ToBase64String($bytes)
    }
    finally {
        $rng.Dispose()
    }
}

$lines = @(
    'ADMIN_EMAIL=admin@libredb.org'
    ('ADMIN_PASSWORD=' + (New-RandomSecret))
    ('JWT_SECRET=' + (New-RandomSecret))
    'USER_EMAIL=user@libredb.org'
    ('USER_PASSWORD=' + (New-RandomSecret))
)
# CreateNew also prevents overwriting a file created between the check and write.
$stream = [System.IO.File]::Open($envPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
try {
    $content = [System.Text.UTF8Encoding]::new($false).GetBytes(($lines -join "`n") + "`n")
    $stream.Write($content, 0, $content.Length)
}
finally {
    $stream.Dispose()
}
Write-Host 'Created local .env with random credentials. Open it privately in your editor.'
