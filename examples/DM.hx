package examples;

import hxbot.Bot;

using StringTools;

class DM {
  static var token:String = "TOKEN HERE";

  static function main() {
    var bot = new Bot(token);

    bot.onReady.add(function(_) {});

    bot.onMessage.add(function(message) {
      if (message.content.startsWith("!dm ")) {
        var parts = message.content.split(" ");
        if (parts.length >= 3) {
          var userId = parts[1];
          if (userId.startsWith("<@") && userId.endsWith(">")) {
            userId = userId.substr(2, userId.length - 3);
          }
          var msgParts = parts.slice(2);
          var dmText = msgParts.join(" ");
          bot.sendDM(userId, dmText);
        } else {
          bot.replyMessage(message.channel_id, "Usage: `!dm <userId> <message>`", message.id);
        }
      }
    });

    bot.onInteraction.add(function(data) {});

    bot.startPolling();
  }
}
