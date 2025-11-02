package examples;

import hxbot.Bot;

using StringTools;

class Infos {
  static var token:String = "TOKEN HERE";
  static var guildId:String = "GUILD ID HERE";

  static function main() {
    var bot = new Bot(token);

    bot.onReady.add(function(_) {});

    bot.onMessage.add(function(message) {
      if (message.content == "!serverinfo") {
        bot.fetchGuild(guildId, function(guild) {
          var memberCount = Reflect.hasField(guild, "approximate_member_count")
            ? guild.approximate_member_count
            : (Reflect.hasField(guild, "member_count") ? guild.member_count : 0);
          var embed = Bot.createEmbed(
            "Server Info: " + guild.name,
            "ID: " + guild.id + "\nOwner:  <@" + guild.owner_id + ">\nMembers: " + memberCount,
            0x3498DB
          );
          bot.sendMessage(message.channel_id, "", null, [embed]);
        });
      }

      if (message.content.startsWith("!userinfo")) {
        var parts = message.content.split(" ");
        var targetId:String;
        if (parts.length > 1) {
          targetId = parts[1];
          if (targetId.startsWith("<@") && targetId.endsWith(">")) {
            targetId = targetId.substr(2, targetId.length - 3);
          }
        } else {
          targetId = message.author.id;
        }
        bot.fetchUser(targetId, function(user) {
          var embed = Bot.createEmbed(
            "User Info: " + user.username,
            "ID: " + user.id + "\n" +
            "Discriminator: #" + user.discriminator + "\n" +
            "Bot: " + (user.bot ? "Yes" : "No"),
            0xAA66CC
          );
          Reflect.setProperty(embed, "thumbnail", { url: "https://cdn.discordapp.com/avatars/" + user.id + "/" + user.avatar + ".png" });
          bot.sendMessage(message.channel_id, "", null, [embed]);
        });
      }

      if (message.content == "!roles") {
        bot.fetchRoles(guildId, function(roles) {
          var roleList = roles.map(function(role) {
            return role.name + " (ID: " + role.id + ")";
          }).join("\n");
          var embed = Bot.createEmbed(
            "Server Roles",
            roleList,
            0xFF5733
          );
          bot.sendMessage(message.channel_id, "", null, [embed]);
        });
      }
    });

    bot.onInteraction.add(function(data) {});

    bot.startPolling();
  }
}
