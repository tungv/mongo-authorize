global.logLevel = 'ALL'

fs = require 'fs'
_ = require 'lodash'
yaml = require 'js-yaml'
mongoose = require 'mongoose'
logger = require('log4js').getLogger('index')
logger.setLevel global.logLevel

Parser = require './parser.coffee'
errors = require './errors.coffee'

class Authorizr
  @matchPatter = pattern = (rule)->
    rule.match /(?=(^|\s*))(user\.\w+(\.\w*)*)/g

  @replaceMatched = replace = (rule, context)->
    matched = pattern rule
    matched?.forEach (match)->
      getter = new Function ['context'], "return context.#{match}"
      try
        value = getter(context)
      catch
        value = 'undefined'

      rule = rule.split(match).join(JSON.stringify(value))


    return rule

  constructor: (config)->
    @parser = new Parser
    @rules = {}
    @rulesRoot = config?.rulesRoot
    @readDir() if @rulesRoot

  readYaml: (path)->
    fullPath = @rulesRoot + '/' + path
    @parser.parseFile fullPath

  applyRules: (content)->
    @parser.parseRule content

  readDir: ->
    files = fs.readdirSync @rulesRoot
    @applyRules @readYaml file for file in files


  makeQuery: (resource, context)->
    condition = @query resource, context
    Model = mongoose.model resource
    Model.find condition

  query: (resource, context)->
    rule = @parser.parsed[resource]['query']


    #console.log 'rule', "[" + rule + "]"

    rule = replace rule, context
    return Model.find() unless rule

    #console.log 'rule', "[" + rule + "]"

    optimized = @optimize rule

    #console.log 'optimized', "[" + JSON.stringify(optimized) + "]"

    return optimized

  optimize: (rule)->
    ## only optimize rule expression (string)
    return rule if typeof rule isnt 'string'

    ## try to simplify this.a === "b" into {a: "b"}
    ## rule must match something === something or something == something
    ## one and only one part has pattern of this.*
    matched = rule.match /^return\s*([^=]+)\s?===?\s?([^;]+)\s*(;\n*)?$/
    if matched and matched[1] and matched[2]
      #console.log 'matched',  matched[1], matched[2]
      leftSide = matched[1].trim()
      rightSide = matched[2].trim()
      [hasThis, theOther] = if leftSide.match(/^(this\..+)$/)
      then [leftSide, rightSide]
      else [rightSide, leftSide]

      theOtherCorrect = !theOther.match((/^(this\..+)$/))
      hasThisCorrect = !!hasThis.match(/^(this\..+)$/)

      #console.log 'hasThis', hasThis, 'correct?', hasThisCorrect
      #console.log 'theOther', theOther, 'correct?', theOtherCorrect

      ## `has this` part must have 'this.' and `the other` must not have 'this.'
      if theOtherCorrect and hasThisCorrect
        obj = {}
        obj[hasThis.substr(5)] = try
          JSON.parse(theOther)
        catch ex
          undefined

        return obj
      else if theOtherCorrect
        ## this case is that both sides are fixed expression
        try
          #console.log 'both side are fixed', rule
          ## remove 'return ' before eval'ing
          isTrue = eval rule.substr 7
          return {$where: 'return ' + if isTrue then 'true;' else 'false;'}
        catch ex
          #console.warn 'ex', ex

    else
      #console.log 'not matched', matched



    ## unable to optimize
    return $where:rule

module.exports = Authorizr
