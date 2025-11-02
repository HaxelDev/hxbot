package examples;

import hxbot.Bot;

class SetPresence {
  static var token:String = "TOKEN HERE";

  static function main() {
    var bot = new Bot(token);

    bot.onReady.add(function(_) {
      bot.setPresence(Status.ONLINE, [
        { name: "HaxeBot", type: ActivityType.PLAYING }
      ]);
    });

    bot.onMessage.add(function(message) {});

    bot.onInteraction.add(function(data) {});

    bot.startPolling();
  }
}
