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
    @parser.applyContext resource, 'query', context

module.exports = Authorizr
