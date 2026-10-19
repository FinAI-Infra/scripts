
param(
    [Parameter(Mandatory = $true)]
    [string]$RegistrationToken
)

$ErrorActionPreference = "Stop"

$agent = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent" -ErrorAction SilentlyContinue

if ($agent.IsRegistered -eq 1) {
    Write-Output "AVD Agent is already registered. Skipping installation."
    exit 0
}

$agentUrl = "https://go.microsoft.com/fwlink/?linkid=2310011"
$bootUrl  = "https://go.microsoft.com/fwlink/?linkid=2311028"

$agentMsi = "$env:TEMP\AVDAgent.msi"
$bootMsi  = "$env:TEMP\AVDBootLoader.msi"

Invoke-WebRequest -Uri $agentUrl -OutFile $agentMsi
Invoke-WebRequest -Uri $bootUrl -OutFile $bootMsi

$agent = Start-Process msiexec.exe `
    -ArgumentList "/i `"$agentMsi`" /quiet /norestart REGISTRATIONTOKEN=$RegistrationToken" `
    -Wait -PassThru

if ($agent.ExitCode -notin @(0, 3010)) {
    throw "AVD Agent installation failed: $($agent.ExitCode)"
}

$boot = Start-Process msiexec.exe `
    -ArgumentList "/i `"$bootMsi`" /quiet /norestart" `
    -Wait -PassThru

if ($boot.ExitCode -notin @(0, 3010)) {
    throw "AVD Boot Loader installation failed: $($boot.ExitCode)"
}

