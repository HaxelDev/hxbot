package examples;

import hxbot.Bot;

class Cats {
  static var token:String = "TOKEN HERE";

  static function main() {
    var bot = new Bot(token);

    bot.onReady.add(function(_) {});

    bot.onMessage.add(function(message) {
      if (message.content == "!cats") {
        var url = "https://nekos.life/api/v2/img/meow";
        var http = new haxe.Http(url);
        http.onData = function(data:String):Void {
          try {
            var js = haxe.Json.parse(data);
            var imageUrl:String = js.url;
            var embed = Bot.createEmbed(
              "CATS! 🐱",
              "",
              0x00FF00
            );
            Reflect.setProperty(embed, "image", { url: imageUrl });
            bot.sendMessage(message.channel_id, "", null, [embed]);
          } catch (e:Dynamic) {
            Sys.println("Parsing API response failed: " + e);
            bot.sendMessage(message.channel_id, "An error occurred while processing the API response.");
          }
        };
        http.onError = function(err:String):Void {
          Sys.println("HTTP error fetching image: " + err);
          bot.sendMessage(message.channel_id, "An error occurred while fetching the image.");
        };
        http.request(false);
      }
    });

    bot.onInteraction.add(function(data) {});

    bot.startPolling();
  }
}
