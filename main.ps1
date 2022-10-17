$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

try {
    . ".\Classes.ps1"
} catch {
    Write-Host "Was not able to load classes.ps1." -f red
    throw $_
}

Write-Host "Please provide server data." -f Cyan
$serverAddress = Read-Host "Address (localhost)"
if ($serverAddress -eq "") { $serverAddress = "localhost" }

$serverPort = Read-Host "Port (25575)"
if ($serverPort -eq "") { $serverPort = 25575 }

$Password = Read-Host "Password"

# Connect and authenticate
try {
    $RconClient = New-Object RconClient $serverAddress, $serverPort
    $RconClient.Authenticate($Password)
} catch {
    if ($RconClient.IsConnected()) { $RconClient.Quit() }
    throw $_
}

# Send commands
''; Write-Host 'You are now connected. Abort with "quit".' -f yellow
while ($true) {
    Write-Host "> " -NoNewLine
    $command = $Host.UI.ReadLine()
    try {
        if ($command -eq "quit") {
            $RconClient.Quit()
            exit
        }

        $response = $RconClient.Send($Command)

        # Specific to minecraft
        $response.split("/") | % { Write-Host "/$_" }
    } catch {
        throw $_
    }
}