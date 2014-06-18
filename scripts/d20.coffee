# Description
#   Roll all kinds of dice
#
# Commands:
#   roll XdY - roll X Y-sided dice
#   roll XdY>Z - roll X Y-sided dice and report the number greater than or equal to Z
#   roll XdY! - roll X Y-sided exploding dice (roll additional dice for each result that equals Y)
#   roll XdY!>Z - Above combined
#   roll Xdf - roll X FATE/Fudge dice (+, +, ' ', ' ', -, -)
#   roll fate - roll 4 FATE dice
#   roll XdY - roll X Y-sided dice
#   roll XdY - roll X Y-sided dice

_ = require 'underscore'

roll = (num, sides, explode=false) ->
  return [] if num == 0
  results = []
  _(num).times ->
    results.push(Math.floor(Math.random() * sides) + 1)
  if explode
    explosions = _.filter(results, (value)->
      return value == sides
    )

    return results.concat roll(explosions.length, sides, explode=true)
  return results

roll_sum = (num, sides, mod=0, explode=false, msg) ->
  msg.send "Rolling #{num} #{if explode then 'exploding' else ''} #{sides}-sided dice #{if mod != 0 && mod? then mod else ''}"
  results = roll(num, sides, explode)
  sum = _.reduce(results, (memo, num) ->
    return memo + num
  , 0)

  msg.send "#{sum + parseInt(mod)} ( #{results.join ', '} ) #{results.length - num} explosions"

fate_rank = (num)->
  rank = switch "#{num}"
    when '1'
      'Average (+1)'
    when '2'
      'Fair (+2)'
    when '3'
      'Good (+3)'
    when '4'
      'Great (+4)'
    when '5'
      'Superb (+5)'
    when '6'
      'Fantastic (+6)'
    when '7'
      'Epic (+7)'
    when '8'
      'Legendary (+8)'
    when '0'
      'Mediocre (+0)'
    when '-1'
      'Poor (-1)'
    when '-2'
      'Terrible (-2)'
    else
      if num > 0 then "+#{num}" else "#{num}"
  return rank

roll_fate = (num, mod=0, msg)->
  msg.send "Rolling #{num} FATE dice #{if mod != 0 then mod else ''}"
  fate_dice = {'-1': '-', 0: '_', 1: '+'}
  results = []
  total = 0
  _.each(roll(num, 3), (num)->
    results.push fate_dice[num-2]
    total += num-2
  )
  msg.send "#{fate_rank(total + parseInt(mod))}: #{results.join(', ')}"

roll_target = (num, sides, target, explode=false, msg)->
  prefix = _.first(target)
  value = target.slice(1)
  if prefix == '>'
    ending = 'or more'
    successful = (num)->
      return num >= parseInt(value)
  else
    ending = 'or less'
    successful = (num)->
      return num <= parseInt(value)
  msg.send "Rolling #{num} #{sides}-sided dice targeting #{value} #{ending}"
  results = roll(num, sides, explode)
  successes = _.filter(results, (num)->
    successful(num)
  )
  msg.send "#{successes.length} Success#{if successes.length == 1 then '' else 'es' }: ( #{results.join(', ')} )"

module.exports = (robot) ->
  robot.hear /\/roll (\d+)df((?:\+|-)\d+)?$/i, (msg) ->
    roll_fate(msg.match[1], msg.match[2], msg)
  robot.hear /\/roll fate((?:\+|-)\d+)?$/i, (msg) ->
    roll_fate(4, msg.match[1], msg)

  robot.hear /\/roll (\d+)d(\d+)(!)?((?:<|>)\d+)?((?:\+|-)\d+)?$/i, (msg) ->
    num = parseInt(msg.match[1])
    sides = parseInt(msg.match[2])
    explode = msg.match[3] == '!'
    target = msg.match[4]
    mod = msg.match[5]

    if target
      roll_target(num, sides, target, explode, msg)
    else
      roll_sum(num, sides, mod, explode, msg)
