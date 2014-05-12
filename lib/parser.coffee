yaml = require 'js-yaml'
fs = require 'fs'
errors = require './errors.coffee'
_ = require 'lodash'

module.exports = class Parser
  constructor: (@parsed = {})->

  parseFile: (filePath)->
    data = yaml.safeLoad fs.readFileSync(filePath, 'utf8')
    resource = data?.meta?.resource
    throw new errors.InvalidFileError filePath, 'missing meta.resource' unless resource?
    @parseRule data

  parseRule: (data)->
    resource = data?.meta?.resource
    throw new errors.InvalidRuleError data, 'missing meta.resource' unless resource?

    data.meta.language = data.meta.language or 'coffee'

    @normalizeRule resource, data.meta.language, ruleName, rules for ruleName, rules of data.rules

    #console.log "@parsed[#{resource}].rules", @parsed[resource].rules
    return @parsed[resource]

  normalizeRule: (resource, language, name, rules)->
    resourceObj = @parsed[resource] or {
      meta:
        resource: resource
      rules: {}
    }

    rulesObj = resourceObj.rules[name] or []
    #console.log 'rules', rules

    optimizer = Optimizer.create language

    @recursiveNormalize rules, optimizer, rulesObj

    resourceObj.rules[name] = rulesObj
    @parsed[resource] = resourceObj

  recursiveNormalize: (rules, optimizer, rulesObj, level=1)->
    #console.log 'level', ++level
    padding = (new Array ++level).join('==') + ' '


    if _.isArray rules.either
      #console.log(padding + 'either', arguments[0], arguments[2])
      $or = []
      rulesObj.push {$or}
      for rule in rules.either
        @recursiveNormalize rule, optimizer, $or, level

    if _.isArray rules.all
      #console.log(padding + 'and', arguments[0], arguments[2])
      $and = []
      rulesObj.push {$and}
      for rule in rules.all
        @recursiveNormalize rule, optimizer, $and, level

    else if _.isArray rules
      #console.log(padding + 'array', arguments[0], arguments[2])
      for rule in rules
        @recursiveNormalize rule, optimizer, rulesObj, level

    else if _.isString rules
      #console.log(padding + 'string', arguments[0], arguments[2])
      rulesObj.push optimizer.optimize rules

  applyContext: (context, rules=[])->


class Optimizer
  @create: (language)->
    switch language
      when 'coffee' then return new @CoffeeScript()

  @getter: (jsCode)->
    ## if it has this, skip eval'ing
    if jsCode.match /this/ then return jsCode

    try
      fn = new Function [], jsCode
      return fn()
    catch ex
      return jsCode



class Optimizer.CoffeeScript extends Optimizer
  coffee = require 'coffee-script'

  parse = (coffeeCode)->
    try
      jsCode = coffee.compile 'return ' + coffeeCode, {bare:true}
      return jsCode.split('\n').join('')
    catch ex
      console.error ex, coffeeCode
      throw new Error 'syntax error: cannot parse coffee-script'

  optimize: (rule)->
    log = off
    #console.log 'OPTIMIZE', rule
    matched = rule.match /^\s*([^=]+)(\s?==\s?|\sis\s|\s?<=?\s?|\s?>=?\s?)([^;]+)\s*(;\n*)?$/
    #console.log 'matched', matched

    thisPattern = /^(this\.|@\.?)(.+)$/
    ## 0. whole string
    ## 1. this. or @
    ## 2. path


    if matched and matched[1] and matched[2] and matched[3]
      #console.log 'matched',  matched[1], matched[2]
      leftSide = matched[1].trim()
      rightSide = matched[3].trim()
      operator = matched[2].trim()
      [hasThis, theOther, swap] = if leftSide.match thisPattern
      then [leftSide, rightSide, false]
      else [rightSide, leftSide, true]

      theOtherCorrect = !theOther.match thisPattern
      hasThisCorrect = !!hasThis.match thisPattern


      log and console.log 'hasThis', hasThis, 'correct?', hasThisCorrect
      log and console.log 'theOther', theOther, 'correct?', theOtherCorrect
      log and console.log 'operator', operator, 'swap', swap

      ## `has this` part must have 'this.' and `the other` must not have 'this.'
      if theOtherCorrect and hasThisCorrect
        path = hasThis.replace thisPattern, ()-> arguments[2]
        #console.log 'this path', path
        obj = {}
        try
          value = Optimizer.getter parse theOther
          switch operator
            when 'is', '==' then obj[path] = value
            when 'isnt', '!=' then obj[path] = $not:value
            when '<='
              obj[path] = if swap then $gte:value else $lte:value
            when '>='
              obj[path] = if swap then $lte:value else $gte:value
            when '<'
              obj[path] = if swap then $gt:value else $lt:value
            when '>'
              obj[path] = if swap then $lt:value else $gt:value

        catch ex
          console.error 'ex', ex


        return obj


    else
      console.log 'not matched', matched


    return {$where: Optimizer.getter parse rule}
