# Setup

This guide assumes that you already have experience hosting Minecraft servers. It only covers the configuration specific to AmongMC.

## 1. Clone the Repository

Clone this repository to a folder of your choice.

## 2. Adjust Server Memory

Open the `start.bat` file with a text editor and change the `-Xms` and `-Xmx` parameters to the desired amount of memory.

The default value is **4 GB**, which proved to be sufficient during testing.

## 3. Linux

The repository only includes a `start.bat` file.

If you are using Linux, create an equivalent `.sh script` containing the same JVM parameters. This guide assumes that you already know how to start a Paper server through the command line.

## 4. Set Up a Connection Method

To play over the internet, you will need to use some form of connection between the players.

The server can be hosted using **Port Forwarding**, but **this is not recommended**.

> **Never enable a DMZ on your router to host the server.** This exposes your machine directly to the internet and represents a significant security risk.

The recommended alternatives are:

- **Radmin VPN** for groups where all players are using the Java Edition on a computer.
- **ZeroTier** when there are players using the Bedrock Edition.

## 5. (Optional) Voice Synchronization with Discord

AmongMC has optional support for automatically synchronizing player mutes in a Discord voice channel during games.

To use it:

- Create a bot through the Discord Developer Portal (or use an existing one).
- Invite the bot to the server where the games will take place.
- Edit the file:

```text
server/plugins/Skript/scripts/changeme.sk
```

and fill in, **inside quotation marks**:

- Bot token
- Server ID (Guild ID)
- ID of the voice channel used for games

If you have never created a Discord bot before, a quick internet search will show the complete process, which can be done in just a few minutes.

## 6. Start the Server

Run the `start.bat` file (or its Linux equivalent).

On the first startup, Paper will automatically download the required libraries.

## Done!

The server is now configured and ready to use.

To learn about the game mechanics and discover all implemented features, see the **gameplay.md** file.