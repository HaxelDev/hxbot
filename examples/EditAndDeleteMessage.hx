package examples;

import hxbot.Bot;

using StringTools;

class EditAndDeleteMessage {
  static var token:String = "TOKEN HERE";

  static function main() {
    var bot = new Bot(token);

    bot.onReady.add(function(_) {});

    bot.onMessage.add(function(message) {
      if (message.content.startsWith("!delete")) {
        if (Reflect.hasField(message, "message_reference") && message.message_reference != null && Reflect.hasField(message.message_reference, "message_id")) {
          var toDeleteId:String = message.message_reference.message_id;
          var channelId:String = message.channel_id;
          bot.deleteMessage(channelId, toDeleteId, function(success) {
            if (success) {
              bot.replyMessage(channelId, "Deleted replied message `" + toDeleteId + "`", message.id);
            } else {
              bot.replyMessage(channelId, "Failed to delete message. Make sure the ID is correct and I have permission.", message.id);
            }
          });
        } else {
          bot.replyMessage(message.channel_id, "You must reply to a message with `!delete` to delete it.", message.id);
        }
      }

      if (message.content.startsWith("!edit ")) {
        if (Reflect.hasField(message, "message_reference") && message.message_reference != null && Reflect.hasField(message.message_reference, "message_id")) {
          var toEditId:String = message.message_reference.message_id;
          var channelId:String = message.channel_id;
          var newContent:String = message.content.substr(6);
          bot.editMessage(channelId, toEditId, newContent);
          bot.replyMessage(channelId, "Edited message `" + toEditId + "`", message.id);
        } else {
          bot.replyMessage(message.channel_id, "You must reply to a message with `!edit <new content>` to edit it.", message.id);
        }
      }
    });

    bot.onInteraction.add(function(data) {});

    bot.startPolling();
  }
}
