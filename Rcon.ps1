$serverAddress = "localhost"
$serverPort = 25575

. ".\Classes.ps1"

function Send-TCPRequest {
    Param(
        $obj
    )

    try {
        # Create Socket
        $Sock = [System.Net.Sockets.Socket]::New(
            [System.Net.Sockets.AddressFamily]::InterNetwork,
            [System.Net.Sockets.SocketType]::Stream,
            [System.Net.Sockets.ProtocolType]::TCP
        )

        $Sock.Connect($serverAddress, $serverPort)
        $Sock.Send($obj) | Out-Null

        # Receive request
        $buffer = New-Object System.Byte[] 40
        $Sock.Receive($buffer)
        
        return $buffer
    } catch {
        throw $_
    } finally {
        $Sock.Close()
    }
}

function Send-RconPacket {
    Param(
        [Parameter(Mandatory=$true)]
        [String] $Command,
        
        [Parameter(Mandatory=$false)]
        [Switch] $Authenticate
        
    )

    $cmdType = if ($Authenticate.IsPresent) { 3 } else { 2 }
    $splat = @(
        $cmdType,
        $Command
    )

    try {
        $RconPacket = New-Object RconPacket $splat
        $response = Send-TCPRequest $RconPacket.Construct()

        # Server will return FF FF FF FF (-1) in the ID field if auth failed or not authenticated
        $responseError = ((Compare-Object $response[5..8] @(,0xFF * 4)).Count -eq 0)

        # Parse according to auth
        if ($responseError) {
            $errorMsg = if ($Authenticate.IsPresent) {
                            throw "Authentication failure."
                        } else {
                            throw "Server did not accept command."
                        }

            throw $errorMsg
        } else {
            return $true
        }
    } catch {
        throw $_
    }
}