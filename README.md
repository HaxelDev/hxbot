# HxBot

[![License: MIT](https://img.shields.io/github/license/Souvic/createmypypackage)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/HaxelDev/hxbot/pulls)
[![WIP](https://img.shields.io/badge/status-WIP-orange.svg)](https://github.com/HaxelDev/hxbot)

<img src="banner.png" alt="HxBot Logo">

> ⚠️ **Project Status:** Work in Progress  
> HxBot is currently under active development. Features, structure, and APIs are subject to change.  
> Contributions, ideas, and feedback are welcome!

---

## 🧠 About

**HxBot** is a Discord bot built with [Haxe](https://haxe.org/) (and optionally integrating with Node.js) designed for modularity, extensibility, and modern Discord interactions.  
The goal is to provide a flexible base for developing bots using HaxeFlixel-inspired structure and cross-language compatibility.

---

## 🚀 Features (so far)

- Basic WebSocket connection to the Discord Gateway
- Automatic heartbeat and reconnect handling
- Message events (`onMessage`, `onReady`, and more)
- Slash command and button interaction support
- Easy helpers for:
  - Sending messages and replies
  - Creating embeds, buttons, and action rows
  - Responding to interactions

---

## 💻 Example Usage

```haxe
import hxbot.Bot;

class Main {
  static function main() {
    var bot = new Bot("YOUR_TOKEN_HERE");

    bot.onReady.add(_ -> trace("Bot is ready!"));

    bot.onMessage.add(message -> {
      if (message.content == "!ping")
        bot.replyMessage(message.channel_id, "Pong!", message.id);
    });

    bot.startPolling();
  }
}
```

---

# 📜 License

[MIT License](LICENSE) © 2025
Developed by [HaxelDev](https://github.com/HaxelDev)

