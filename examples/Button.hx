package examples;

import hxbot.Bot;

class Button {
  static var token:String = "TOKEN HERE";

  static function main() {
    var bot = new Bot(token);

    bot.onReady.add(function(_) {});

    bot.onMessage.add(function(message) {
      if (message.content == "!button") {
        var row = Bot.createActionRow([
          Bot.createButton("Click Me!", "button", 1, { name: "🔥" })
        ]);
        var embed = Bot.createEmbed("Title", "Embed description", 0xFFAA00);
        bot.sendMessage(message.channel_id, "Click the button below:", [row], [embed]);
      }
    });

    bot.onInteraction.add(function(data) {
      if (data.type == 3) {
        var customId = data.data.custom_id;
        switch(customId) {
          case "button":
            bot.respondInteraction(data, function(d:Dynamic) {
              return { content: "🔥 Button clicked!" };
            });
          default:
        }
      }
    });

    bot.startPolling();
  }
}
