$listeningPort = 5000

$connectedUsers = [System.Collections.ArrayList]@()

function Console-Log($message) {
    Write-Output "$(Get-Date -UFormat "%x %T") - $message"
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$listeningPort/")
$listener.Start()
Console-Log "Webhook Jellyfin server listening on port $listeningPort..."

function Enable-GPU {
    [System.Environment]::SetEnvironmentVariable('JellyFinNeedGpu',$true,'User')
    Console-Log "Activating the GPU..."
    Start-Process -FilePath "pnputil" -ArgumentList "/enable-device PCI\VEN_8086&DEV_56A1&SUBSYS_60021849&REV_08\6&1c677e3c&0&00080008" -NoNewWindow -Wait
}

function Disable-GPU {
    [System.Environment]::SetEnvironmentVariable('JellyFinNeedGpu',$false,'User')
    Console-Log "The GPU will be disabled in 5 minutes if there is no more activity"
    Start-Job -ScriptBlock {
        Start-Sleep -Seconds 300
        if ([System.Environment]::GetEnvironmentVariable('JellyFinNeedGpu','User') -eq $false) {
            Start-Process -FilePath "pnputil" -ArgumentList "/disable-device PCI\VEN_8086&DEV_56A1&SUBSYS_60021849&REV_08\6&1c677e3c&0&00080008" -NoNewWindow -Wait
        }
    }
}

function Handle-Request {
    param ($context)
    try {
        $request = $context.Request
        $response = $context.Response

        $reader = [System.IO.StreamReader]::new($request.InputStream)
        $body = $reader.ReadToEnd() | ConvertFrom-Json
        $reader.Close()

        $event = $body.Event
        $user = $body.User
        Console-Log "Event received : $event from $user"

        if ($event -eq "playback.start" -and -not $connectedUsers.Contains($user)) {
            $connectedUsers.Add($user) | Out-Null
            if ($connectedUsers.Count -eq 1) {
                Enable-GPU
            }
        } elseif ($event -eq "playback.stop" -and $connectedUsers.Contains($user)) {
            $connectedUsers.Remove($user)
            if ($connectedUsers.Count -eq 0) {
                Disable-GPU
            }
        }

        Console-Log "Users currently connected : $($connectedUsers -join ', ')"
        $response.StatusCode = 200
        $response.StatusDescription = "OK"
        $response.Close()
    } catch {
        Console-Log "Error : $_"
    }
}

while ($true) {
    try {
        if ($listener.IsListening) {
            $context = $listener.GetContext()
            Handle-Request -context $context
        }
    } catch {
        Console-Log "Error in the main loop : $_"
    }
}

$listener.Stop()