# Description
#   Roll all kinds of dice
#
# Commands:
#   roll XdY - roll X Y-sided dice
#   roll XdY>Z - roll X Y-sided dice and report the number greater than or equal to Z
#   roll XdY! - roll X Y-sided exploding dice (roll additional dice for each result that equals Y)
#   roll Xdf - roll X FATE/Fudge dice (+, +, ' ', ' ', -, -)
#   roll XdY - roll X Y-sided dice
#   roll XdY - roll X Y-sided dice
#   roll XdY - roll X Y-sided dice

module.exports = (robot) ->
  robot.respond /(\d+)d(\d+)/i, (msg) ->
    msg.send "Rolling #{msg[1]} #{msg[2]}-sided dice"
