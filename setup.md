# Setup

This guide assumes that you already have experience hosting Minecraft servers. It only covers the configuration specific to AmongMC.

## 1. Clone the Repository

Clone this repository to a folder of your choice.

## 2. Install the Server Pack

Run the installer for your platform:

- **Windows:** `install.bat`
- **Linux / macOS / Git Bash / WSL:** `./install.sh`

This will download Paper and all plugins defined in `plugins.json`. If any plugin fails to install automatically (e.g., due to Cloudflare protection on SpigotMC), you will need to download it manually, place it in the `server/plugins/` folder (checking that the version matches what's in `plugins.json`), and optionally open an issue if you believe it's a bug.

You can pass `--accept-eula` to automatically accept Mojang's EULA. If you do this, you are agreeing to the EULA. Otherwise, `eula.txt` will be created for you to accept manually.

## 3. Adjust Server Memory

Open the `server/start.bat` (not the one in the project root folder, as it is just a shortcut) or `server/start.sh` file with a text editor and change the `-Xms` and `-Xmx` parameters to the desired amount of memory.

The default value is **4 GB**, which proved to be sufficient during testing.

## 4. Linux Configuration

The repository now includes both `start.bat` and `start.sh` scripts.

If you are using Linux, use `start.sh` instead of `start.bat`. Additionally, edit `server/spigot.yml` and change the `restart-script` parameter from `start.bat` to `start.sh` so that the server can restart properly.

## 5. Set Up a Connection Method

To play over the internet, you will need to use some form of connection between the players.

The server can be hosted using **Port Forwarding**, but **this is not recommended**.

> **Never enable a DMZ on your router to host the server.** This exposes your machine directly to the internet and represents a significant security risk.

The recommended alternatives are:

- **Radmin VPN** for groups where all players are using the Java Edition on a computer.
- **ZeroTier** when there are players using the Bedrock Edition.

## 6. (Optional) Voice Synchronization with Discord

AmongMC has optional support for automatically synchronizing player mutes in a Discord voice channel during games.

To use it:

- Create a bot through the Discord Developer Portal (or use an existing one).
- Invite the bot to the server where the games will take place.
- Edit the file:

```text
server/plugins/Skript/scripts/changeme.sk
```

**Quick Access:** You can also open this file directly using the **`DiscordSetup.lnk`** shortcut located in the **root folder of the project**.

and fill in, **inside quotation marks**:

- Bot token
- Server ID (Guild ID)
- ID of the voice channel used for games

If you have never created a Discord bot before, a quick internet search will show the complete process, which can be done in just a few minutes.

## 7. Start the Server

Run `start.bat` (Windows) or `./start.sh` (Linux / macOS / Git Bash / WSL) from the project root.

On the first startup, Paper will automatically download the required libraries.

## 8. Done!

The server is now configured and ready to use.

To learn about the game mechanics and discover all implemented features, see the **gameplay.md** file.