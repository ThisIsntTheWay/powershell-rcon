# About
RCON client written in PowerShell.  
Conforms to the RCON protocol specification as declared by the [valve dev docs](https://developer.valvesoftware.com/wiki/Source_RCON_Protocol).

## Usage
```PowerShell
# Connect to server and authenticate
$RconClient = New-Object RconClient <Address>, <Port>
$RconClient.Authenticate(<Password>)

# Send stuff
$RconClient.Send(<Command>)

# Properly disconnect from server, object must be cleaned up manually
$RconClient.Quit()
```
## Quickstart
Start up `main.ps1` and provide your server details.  
Once connected, you can start typing away commands.

![](https://user-images.githubusercontent.com/13659371/196057294-48b57fa8-48e4-40f6-8f96-a994638027ab.png)
