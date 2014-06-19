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
#   set roleplaying system <system>

_ = require 'underscore'

module.exports = (robot) ->
  game = new Game robot
  robot.respond /set roleplaying system (\w+)/i, (msg) ->
    systems = {
      'New World of Darkness': 'nwod',
      'nwod': 'nwod',
      'Old World of Darkness': 'owod',
      'owod': 'owod',
      'Mouse Guard': 'mouse_guard',
      'Fate': 'fate',
      'Fudge': 'fate'
    }

    system = msg.match[1]
    if systems[system]?
      msg.send "Setting system to be #{system}"
    else
      msg.send "Unknown system #{system}"

  robot.respond /set init(?:iative)?(?: for (\w+) (?:to|at))? (\d+)/i, (msg) ->
    if msg.match[1]?
      user = msg.match[1]
    else
      user = msg.message.user.mention_name
    score = msg.match[2]
    game.set_initiative(score, user)
    msg.send "Set #{user} to initiative #{score}"

  robot.respond /clear init(?:iative)?/i, (msg)->
    game.clear_initiative()
    msg.send 'Clearing Initiative!'
  robot.respond /init(?:iative)?/i, (msg) ->
    msg.send game.initiative()

  robot.hear /\/roll (\d+)df((?:\+|-)\d+)?$/i, (msg) ->
    game.roll_fate(msg.match[1], msg.match[2], msg)

  robot.hear /\/roll fate((?:\+|-)\d+)?$/i, (msg) ->
    game.roll_fate(4, msg.match[1], msg)

  robot.hear /\/roll (\d+)d(\d+)(!)?((?:<|>)\d+)?((?:\+|-)\d+)?$/i, (msg) ->
    num = parseInt(msg.match[1])
    sides = parseInt(msg.match[2])
    explode = msg.match[3] == '!'
    target = msg.match[4]
    mod = msg.match[5]

    if target
      game.roll_target(num, sides, target, explode, msg)
    else
      game.roll_sum(num, sides, mod, explode, msg)

class Game
  constructor: (@robot) ->
    @robot.brain.on 'loaded', =>
      if @robot.brain.data.roleplaying_game?
        @game = @robot.brain.data.roleplaying_game
      else
        @game = {}

  save: ->
    @robot.brain.data.roleplaying_game = @game

  initiative: ->
    return 'No initiative scores set' if _.isEmpty(@game['initiative'])
    init = @game['initiative']
    sorted = _.sortBy(_.pairs(init), (pair)->
      -1 * pair[1]
    )
    formatted = _.map(sorted, (pair)->
      return "#{pair[0]}: #{pair[1]}"
    )
    return formatted.join("\n")


  clear_initiative: ->
    @game['initiative'] = {}
    @save()

  set_initiative: (score, user) ->
    @game['initiative'] = {} unless @game['initiative']?
    @game['initiative'][user] = score
    @save()

  roll: (num, sides, explode=false) ->
    return [] if num == 0
    results = []
    _(num).times ->
      results.push(Math.floor(Math.random() * sides) + 1)
    if explode
      explosions = _.filter(results, (value)->
        return value == sides
      )

      return results.concat @roll(explosions.length, sides, explode=true)
    return results

  roll_sum: (num, sides, mod=0, explode=false, msg) ->
    msg.send "Rolling #{num} #{if explode then 'exploding' else ''} #{sides}-sided dice #{if mod != 0 && mod? then mod else ''}"
    results = @roll(num, sides, explode)
    sum = _.reduce(results, (memo, num) ->
      return memo + num
    , 0)

    if explode
      ending = "#{results.length - num} explosions"
    else
      ending = ''
    msg.send "#{sum + parseInt(mod)} ( #{results.join ', '} ) #{ending}"

  roll_fate: (num, mod=0, msg)->
    msg.send "Rolling #{num} FATE dice #{if mod != 0 then mod else ''}"
    fate_dice = {'-1': '-', 0: '_', 1: '+'}
    results = []
    total = 0
    _.each(@roll(num, 3), (num)->
      results.push fate_dice[num-2]
      total += num-2
    )
    msg.send "#{fate_rank(total + parseInt(mod))}: #{results.join(', ')}"

  roll_target: (num, sides, target, explode=false, msg)->
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
    results = @roll(num, sides, explode)
    successes = _.filter(results, (num)->
      successful(num)
    )
    if explode
      ending = "#{results.length - num} explosions"
    else
      ending = ''
    msg.send "#{successes.length} Success#{if successes.length == 1 then '' else 'es' }: ( #{results.join(', ')} ) #{ending}"

  fate_rank: (num)->
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
