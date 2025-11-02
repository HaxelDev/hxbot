package examples;

import hxbot.Bot;

class SlashCommands {
  static var token:String = "TOKEN HERE";
  static var appId:String = "APP ID HERE";

  static function main() {
    var bot = new Bot(token);

    bot.onReady.add(function(_) {
      var commands = [
        Bot.createSlashCommand("ping", "Pong answers!"),
        Bot.createSlashCommand("echo", "Repeats your text", [
          Bot.createOption("text", "Text for repetition", 3, true)
        ])
      ];
      bot.registerCommands(appId, commands);
    });

    bot.onMessage.add(function(message) {});

    bot.onInteraction.add(function(data) {
      if (data.type == 2) {
        var name = data.data.name;
        var options = data.data.options;
        switch (name) {
          case "ping":
            bot.respondInteraction(data, (_) -> {
              return { content: "🏓 Pong!" };
            });
          case "echo":
            var msg:String = options != null && options.length > 0 ? options[0].value : "";
            bot.respondInteraction(data, (_) -> {
              return { content: "You said: " + msg };
            });
          default:
        }
      }
    });

    bot.startPolling();
  }
}
