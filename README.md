# About

This script enables **automatic GPU toggling** in Windows when users start/stop watching a media on a JellyFin server.
The goal is to **reduce the power consumption** of the server when the GPU is not active, typically with some Intel GPUs that can go up to 40W of consumption when on 0% load.

# Setup

In order to make the script work, you will need to configure your JellyFin server a little bit :
1. **Download** the latest release of [this specific fork](https://github.com/prochy-exe/jellyfin-plugin-webhook) of the [JellyFin Webhook plugin](https://github.com/jellyfin/jellyfin-plugin-webhook) or any fork with the SessionEnd event.
2. Create a **new folder** in your JellyFin plugin folder, usually ```C:\ProgramData\Jellyfin\Server\plugins```, named ```Webhook_17.0.0.0``` (replace 17.0.0.0 with the latest version of the official repo if you don't want our modified version to be overwritten with auto-update)
3. **Unzip** the content of the downloaded file and **put it** in the folder you just created
4. Open **JellyFin** and go to ```Settings -> Dashboard -> My plugins -> Webhook``` or http://localhost/web/#/configurationpage?name=Webhook if you're directly on the server
5. **Set** your server url
6. **Click** on ```Add Generic Destination```, name it how you want like ```Session Start``` for example, configure the url to be the same as your server and with the same port as the one used in my script, most of the time it will be http://localhost:5000/
7. **Check** ```Playback Start``` and ```Session Start``` in the "Notification Type" section and leave the other boxes by default
8. In the "Template" section, **put the following** : ```{Event: "playback.start", User: "{{NotificationUsername}}"}```
9. **Repeat** the steps 6, 7 and 8 but check ```Playback Stop``` and ```Session End``` instead and set the Template to ```{Event: "playback.stop", User: "{{NotificationUsername}}"}```
10. **Execute** my script in admin mode

## Auto launch on Windows startup

Coming soon...