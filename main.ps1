$serverAddress = "localhost"
$serverPort = 25575

try {
    . ".\Classes.ps1"
} catch {
    Write-Host "Was not able to load classes.ps1." -f red
    throw $_
}

Write-Host "Please provide server data." -f Cyan
$serverAddress = Read-Host "Address"
$serverPort = Read-Host "Port"
$Password = Read-Host "Password"

# Connect and authenticate
try {
    $RconClient = New-Object RconClient $serverAddress, $serverPort
    $RconClient.Authenticate($Password)
} catch {
    if ($RconClient.IsConnected()) { $RconClient.Quit() }
    throw $_
} finally {
}

# Send commands
Write-Host 'You are now connected. Abort with "quit".' -f yellow
while ($true) {
    $command = Read-Host ">"
    try {
        if ($command -eq "quit") {
            $RconClient.Quit()
            exit
        }

        $RconClient.Send($Command)
    } catch {
        throw $_
    }
}