# Gameplay

## Before Starting

To start a game, **at least one player must be a server operator (OP)**.

This can be done through the console with:

```text
op <nickname>
```

---

## Lobby

When joining the server, all players will appear in the lobby.

In the hotbar, each player has items to customize their character:

- 🎨 Choose color

- 👒 Choose hat

Operator players also receive a **compass**, which opens the game settings menu.

Virtually every aspect of the game can be configured through this menu. The names of the settings are self-explanatory.

> **Important:** only one player should edit the settings at a time. Simultaneous changes may cause unexpected behavior.

---

## Number of Players

The game does not have a configured player limit.

However, the recommended number of players is **4 to 10 players**.

The practical limits of the system are:

- **Minimum:** 3 players

- **Maximum:** 16 players

With fewer than **3 players**, the impostor automatically wins.

With more than **16 players**, the color system stops working correctly (there are only 16 available colors), which ends up causing several issues during the game.

---

## Lobby Books

Before starting a game, all players are encouraged to read the books available in the lobby.

They contain important information about the game's controls and mechanics.

---

## Commands

### Operators Only

```text
/start
```

Starts a new game.

```text
/end
```

Ends the current game.

> **Warning:** be careful not to type `/stop` by mistake... this command shuts down the **entire server**. I made this mistake about 20 times during development, so hopefully you won't make the same mistake.

---

## Joining or Leaving During a Game

AmongMC was programmed to handle players joining or leaving during a game.

- If a player joins without having participated from the beginning, they will automatically be placed as a spectator.
- If a player who was already in the game leaves and rejoins, they should return as a ghost, preserving the current game state.

Although this behavior exists, **it has not been extensively tested** and may contain bugs. Whenever possible, players who need to leave should wait until the game has ended before rejoining.

---

## Bedrock Edition Compatibility

AmongMC was developed with **Minecraft Java Edition** as the primary target.

Players using **Bedrock Edition** may encounter some limitations due to differences between the two versions of Minecraft.

Some tasks were deliberately replaced with simpler alternatives on Bedrock Edition because their execution was excessively difficult or inconsistent on that platform.

Even so, any bugs encountered should be reported.

---

## Have Fun!

If you find any bugs, have suggestions, or would like to contribute to the project, feel free to open an Issue on GitHub.

Have fun!