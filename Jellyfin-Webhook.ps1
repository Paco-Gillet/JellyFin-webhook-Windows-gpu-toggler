# Déclare le port d'écoute
$port = 5000

# Initialise la liste des utilisateurs connectés
$connectedUsers = [System.Collections.ArrayList]@()

# Affiche un message dans la console en y ajoutant la date et l'heure
function Console-Log($message) {
    Write-Output "$(Get-Date -UFormat "%x %T") - $message"
}

# Crée un listener HTTP
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Console-Log "Serveur Webhook Jellyfin en écoute sur le port $port..."

# Fonction pour activer la carte graphique Arc A750
function Enable-A750 {
    [System.Environment]::SetEnvironmentVariable('JellyFinNeedGpu',$true,'User')
    Console-Log "Activation de l'Arc A750..."
    Start-Process -FilePath "pnputil" -ArgumentList "/enable-device PCI\VEN_8086&DEV_56A1&SUBSYS_60021849&REV_08\6&1c677e3c&0&00080008" -NoNewWindow -Wait
}

# Fonction pour désactiver la carte graphique Arc A750
function Disable-A750 {
    [System.Environment]::SetEnvironmentVariable('JellyFinNeedGpu',$false,'User')
    Console-Log "Désactivation de l'Arc A750 dans 5 min en cas d'inactivité"
    Start-Job -ScriptBlock {
        Start-Sleep -Seconds 300
        if ([System.Environment]::GetEnvironmentVariable('JellyFinNeedGpu','User') -eq $false) {
            Start-Process -FilePath "pnputil" -ArgumentList "/disable-device PCI\VEN_8086&DEV_56A1&SUBSYS_60021849&REV_08\6&1c677e3c&0&00080008" -NoNewWindow -Wait
        }
    }
}

# Fonction pour gérer les requêtes
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
        Console-Log "Événement reçu : $event de $user"

        if ($event -eq "playback.start" -and -not $connectedUsers.Contains($user)) {
            $connectedUsers.Add($user) | Out-Null
            if ($connectedUsers.Count -eq 1) {
                Enable-A750
            }
        } elseif ($event -eq "playback.stop" -and $connectedUsers.Contains($user)) {
            $connectedUsers.Remove($user)
            if ($connectedUsers.Count -eq 0) {
                Disable-A750
            }
        }

        Console-Log "Utilisateurs en cours de lecture : $($connectedUsers -join ', ')"
        $response.StatusCode = 200
        $response.StatusDescription = "OK"
        $response.Close()
    } catch {
        Console-Log "Erreur : $_"
    }
}

# Boucle principale
while ($true) {
    try {
        if ($listener.IsListening) {
            $context = $listener.GetContext()
            Handle-Request -context $context
        }
    } catch {
        Console-Log "Erreur dans la boucle principale : $_"
    }
}

# Arrête le serveur lorsque terminé
$listener.Stop()
