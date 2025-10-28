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

**HxBot** is a lightweight and modular **Haxe library** for building Discord bots.  
It focuses on providing a clean, type-safe, and flexible API for interacting with the Discord Gateway and REST API — written entirely in [Haxe](https://haxe.org/).

The goal of the project is to make Discord bot development in Haxe easy, efficient, and enjoyable, while staying close to modern Discord API standards.

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

