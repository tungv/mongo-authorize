global.logLevel = 'ALL'

fs = require 'fs'
_ = require 'lodash'
yaml = require 'js-yaml'
mongoose = require 'mongoose'
logger = require('log4js').getLogger('index')
logger.setLevel global.logLevel


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
    @rules = {}
    @rulesRoot = config?.rulesRoot
    @readDir() if @rulesRoot

  readYaml: (path)->
    fullPath = @rulesRoot + '/' + path
    yaml.safeLoad fs.readFileSync(fullPath, 'utf8')

  applyRules: (content)->
    name = content?.meta?.resource
    throw new errors.InvalidFileError path, 'missing meta.resource' unless name?

    language = content.meta.language or 'coffee'

    rules = content.rules

    unless language is 'javascript'
      compiler =  require "./compilers/#{language}.coffee"
      throw new errors.InvalidFileError path, "invalid meta.language (#{ language })" unless compiler?
      rules = compiler.compile rules

    #logger.debug 'rules', rules
    @rules[name] = _.extend {}, @rules[name], rules


  readDir: ->
    files = fs.readdirSync @rulesRoot
    @applyRules @readYaml file for file in files



  makeQuery: (resource, context)->
    condition = @query resource, context
    Model = mongoose.model resource
    Model.find condition

  query: (resource, context)->
    rule = @rules[resource]['query']

    #console.log 'rule', "[" + rule + "]"

    rule = replace rule, context
    return Model.find() unless rule

    #console.log 'rule', "[" + rule + "]"
    return $where:rule

module.exports = Authorizr
