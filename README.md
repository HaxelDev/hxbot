# hxbot

hxbot is a Haxe-based bot for interacting with the Discord Gateway. This project is currently a work in progress (WIP).

## Features

- Connects to the Discord Gateway
- Handles WebSocket communication
- Manages heartbeats to keep the connection alive
- Allows setting bot status
- Event-driven architecture for handling Discord events

## Requirements

- Haxe 4.0 or higher

## Installation

Install the library using `haxelib`:

`haxelib git hxbot https://github.com/HaxelDev/hxbot.git`

## Usage

Compile the project using Haxe:
`haxe build.hxml`
```
-cp src
-main Main
--neko bot.n
--cmd neko bot.n
```

## Logging

The `Log` class provides different logging methods:

- `Log.info(message)`: Logs an informational message.
- `Log.warn(message)`: Logs a warning message.
- `Log.error(message)`: Logs an error message.
- `Log.debug(message)`: Logs a debug message.
- `Log.success(message)`: Logs a success message.
- `Log.important(message)`: Logs an important message.

You can use these logging methods throughout your code to provide visibility into the bot's operations, troubleshoot issues, and track important events.

## Contributing

Contributions are welcome! Please fork the repository and create a pull request with your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/HaxelDev/hxbot/blob/main/LICENSE) file for details.

## Example

Here's a simple example of how you can use `hxbot` to create a bot instance, connect it to Discord, and handle events:

```haxe
import hxbot.Bot;
import hxbot.Log;

var bot = new Bot("YOUR_DISCORD_TOKEN");

bot.on("MESSAGE_CREATE", function(message) {
    Log.info("New message received: " + message.content);
});
```
