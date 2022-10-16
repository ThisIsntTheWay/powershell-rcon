class RconServerAuthException : Exception {
    [string] $additionalData

    RconServerAuthException($Message, $additionalData) : base($Message) {
        $this.additionalData = $additionalData
    }
}

class RconServerCommandException : Exception {
    [string] $additionalData

    RconServerCommandException($Message, $additionalData) : base($Message) {
        $this.additionalData = $additionalData
    }
}

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