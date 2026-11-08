param(
    [string]$OutputDirectory = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

function Read-Secret([string]$Prompt) {
    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

$keytool = (Get-Command keytool.exe -ErrorAction SilentlyContinue)?.Source
if (-not $keytool) {
    $candidates = @(
        "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
        "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool",
        "$env:ProgramFiles\Eclipse Adoptium\jdk-17.0.0.0-hotspot\bin\keytool.exe"
    )
    $keytool = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}
if (-not $keytool) {
    throw 'keytool was not found. Install a JDK 17+ or add its bin directory to PATH.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$keystore = Join-Path $OutputDirectory 'gtn2-debug-signing.jks'
$base64File = Join-Path $OutputDirectory 'GTN2_DEBUG_KEYSTORE_BASE64.txt'
$alias = 'gtn2-debug'
if (Test-Path -LiteralPath $keystore) {
    throw "Refusing to overwrite existing keystore: $keystore"
}

Write-Host 'Create two strong, unique passwords. Save them in a password manager.'
$storePassword = Read-Secret 'Keystore password (minimum 12 characters)'
$keyPassword = Read-Secret 'Private key password (minimum 12 characters)'
if ($storePassword.Length -lt 12 -or $keyPassword.Length -lt 12) {
    throw 'Both passwords must be at least 12 characters.'
}

$env:GTN2_STORE_PASSWORD = $storePassword
$env:GTN2_KEY_PASSWORD = $keyPassword
try {
    $arguments = @(
        '-genkeypair', '-v',
        '-keystore', $keystore,
        '-storetype', 'PKCS12',
        '-alias', $alias,
        '-keyalg', 'RSA',
        '-keysize', '4096',
        '-validity', '10000',
        '-dname', 'CN=GTN2 Debug Signing, OU=Development, O=GTN2, C=PH',
        '-storepass:env', 'GTN2_STORE_PASSWORD',
        '-keypass:env', 'GTN2_KEY_PASSWORD'
    )
    & $keytool @arguments
    if ($LASTEXITCODE -ne 0) { throw 'keytool failed to create the signing key.' }

    $bytes = [IO.File]::ReadAllBytes($keystore)
    [IO.File]::WriteAllText($base64File, [Convert]::ToBase64String($bytes), [Text.Encoding]::ASCII)
    $listArguments = @('-list', '-v', '-keystore', $keystore, '-alias', $alias, '-storepass:env', 'GTN2_STORE_PASSWORD')
    $fingerprint = (& $keytool @listArguments | Select-String 'SHA256:' | Select-Object -First 1).ToString()
}
finally {
    Remove-Item Env:GTN2_STORE_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:GTN2_KEY_PASSWORD -ErrorAction SilentlyContinue
    $storePassword = $null
    $keyPassword = $null
}

Write-Host ''
Write-Host 'GTN2 signing key created.'
Write-Host "Keystore: $keystore"
Write-Host "Base64 secret file: $base64File"
Write-Host "Key alias: $alias"
Write-Host "Certificate: $fingerprint"
Write-Host ''
Write-Host 'Add these four GitHub Actions secrets in the GTN2 repository:'
Write-Host '  GTN2_DEBUG_KEYSTORE_BASE64  <- paste the complete contents of the .txt file'
Write-Host '  GTN2_DEBUG_KEY_ALIAS       <- gtn2-debug'
Write-Host '  GTN2_DEBUG_KEY_PASSWORD    <- the private key password you entered'
Write-Host '  GTN2_DEBUG_STORE_PASSWORD  <- the keystore password you entered'
Write-Host ''
Write-Host 'Keep BOTH generated files in a safe offline backup. Never commit either file.'
