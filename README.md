# 🧠 hxbot

A lightweight Discord bot framework written in [Haxe](https://haxe.org/).  
Currently a **work-in-progress (WIP)** project aiming to provide a simple and fully functional interface for Discord bots using only Haxe standard libraries.

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

