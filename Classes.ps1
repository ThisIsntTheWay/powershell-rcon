class RconPacket {
    # https://developer.valvesoftware.com/wiki/Source_RCON_Protocol
    hidden [byte[]] $pktSize
    [byte[]] $PktId
    [byte[]] $PktCmdType
    [byte[]] $PktCmdPayload

    RconPacket(
        [int] $Type,
        [string] $Command
    ){
        $enc = [System.Text.Encoding]::ASCII

        # Create emmpty bytes[]
        $this.pktSize = [byte[]]::new(4)
        $this.pktId = [byte[]]::new(4)
        $this.PktCmdType = [byte[]]::new(4)
        $this.PktCmdPayload = [byte[]]::new(1)

        # Validate type
        if (($Type -gt 4) -or ($Type -lt 0)) {
            throw "Invalid CMD Type: $Type"
        }

        # Construct Packet
        $this.pktId = $enc.GetBytes(([guid]::NewGuid()).guid.split("-")[1])
        $this.PktCmdType[0] = $type
        $this.PktCmdPayload = $enc.GetBytes($Command) + 0x00
            # Includes \0 terminator

        $this.pktSize = [BitConverter]::GetBytes($this.PktCmdPayload.Length + 9)
            # [BitConverter]::GetBytes() already returns a Byte[] of size 4
    }

    [PSCustomObject] Construct() {
        $returnObj = $this.pktSize + $this.pktId + $this.PktCmdType + $this.PktCmdPayload + 0x00
        return $returnObj
    }
}

class RconClient {
    hidden [System.Net.Sockets.Socket] $_socket
    hidden [bool] $_isAuthenticated

    [string] $ServerAddress
    [int] $ServerPort
    
    RconClient(
        [String]$ServerAddress,
        [int]$ServerPort
    ){
        # Validate params
        if ($ServerPort -gt 65535 -or $ServerPort -le 0) {
            throw "Server port '$ServerPort' is outside of acceptable range."
        }

        # Init class vars
        $this._isAuthenticated = $false
        $this.ServerAddress = $ServerAddress
        $this.ServerPort = $ServerPort

        try {
            $this._socket = [System.Net.Sockets.Socket]::New(
                [System.Net.Sockets.AddressFamily]::InterNetwork,
                [System.Net.Sockets.SocketType]::Stream,
                [System.Net.Sockets.ProtocolType]::TCP
            )

            $this._socket.Connect($serverAddress, $serverPort)
        } catch {
            Write-Host "Server connection has failed." -f red

            throw $_.Exception.Message
        }
    }

    # ============================
    #           Public
    # ============================
    Quit() {
        Write-Warning "Destroying socket."
        if ($this._socket.Connected) {
            $this._socket.Close()
        } else {
            throw "Already in disconnected state."
        }
    }

    Authenticate(
        [string] $Password
    ){
        if ($this._isAuthenticated) {
            throw "Already authenticated."
        }

        $p = New-Object RconPacket 3, $Password
        $response = $this._sendSocket($p)

        # Parse buffer
        # Server will return FF FF FF FF (-1) in the ID field if auth failed or not authenticated
        # The following will return FALSE if ID field is not FF FF FF FF, indicating SUCCESS
        $responseVerdict = ((Compare-Object $response[4..7] @(,0xFF * 4)).Count -gt 0)

        if ($responseVerdict) {
            $this._isAuthenticated = $true
        } else {
            $this._isAuthenticated = $false
            throw "Authentication failed due to bad password."
        }
    }

    [string] Send(
        [string] $Command
    ){
        if (!$this._socket.Connected) {
            throw "Socket is not connected."
        }
        if (!$this._isAuthenticated) {
            throw "Client not yet authenticated."
        }

        # Response begins at the 13th byte
        $t = $this._sendSocket((New-Object RconPacket 2, $Command))
        $response = [System.Text.Encoding]::ASCII.GetString($t[12..($t.length)])

        return $response
    }

    Reconnect() {
        if ($this._socket.Connected) {
            throw "Socket is already connected."
        }

        $this._isAuthenticated = $false
        try {
            $this._socket.Connect($this.ServerAddress, $this.ServerPort)
        } catch {
            throw $_
        }
    }

    # ============================
    #           Private
    # ============================
    [byte[]] _sendSocket(
        [RconPacket] $packet
    ){
        if (!$this._socket.Connected) {
            throw "Socket is not connected."
        }

        try {
            $toSend = $packet.Construct()
            $buf = New-Object System.Byte[] 100
    
            $this._socket.Send($toSend) | Out-Null
            $this._socket.Receive($buf)
    
            return $buf
        } catch {
            throw $_
        }
    }
    
    # ============================
    #           Getters
    # ============================
    [bool] IsAuthenticated() {
        return $this._isAuthenticated
    }

    [bool] IsConnected() {
        return $this._socket.Connected
    }
}