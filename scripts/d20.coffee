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

_ = require 'underscore'

roll = (sides) ->
  Math.floor(Math.random() * sides) + 1

module.exports = (robot) ->
  robot.respond /roll (\d+)d(\d+)/i, (msg) ->
    x = msg.match[1]
    y = msg.match[2]
    msg.send "Rolling #{x} #{y}-sided dice"
    results = []
    _(x).times ->
      results.push roll(y)

    msg.send results.join ', '
