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
    matched.forEach (match)->
      getter = new Function ['context'], "return context.#{match}"
      try
        value = getter(context)
      catch
        value = 'undefined'

      rule = rule.split(match).join(JSON.stringify(value))


    return rule

  constructor: (config)->
    @rules = {}
    @rulesRoot = config?.rulesRoot or process.cwd() + '/rules'
    @readDir()

  readYaml: (path)->
    fullPath = @rulesRoot + '/' + path
    data = yaml.safeLoad fs.readFileSync(fullPath, 'utf8')

    name = data?.meta?.resource
    throw new errors.InvalidFileError path, 'missing meta.resource' unless name?

    language = data.meta.language or 'coffee'

    rules = data.rules

    unless language is 'javascript'
      compiler =  require "./compilers/#{language}.coffee"
      throw new errors.InvalidFileError path, "invalid meta.language (#{ language })" unless compiler?
      rules = compiler.compile rules

    #logger.debug 'rules', rules
    @rules[name] = _.extend {}, @rules[name], rules

  readDir: ->
    files = fs.readdirSync @rulesRoot
    @readYaml file for file in files

  query: (resource, context)->
    rule = @rules[resource]['query']

    rule = replace rule, context
    return Model.find() unless rule

    #console.log 'rule', "[" + rule + "]"

    Model = mongoose.model resource
    Model.find $where:rule

module.exports = Authorizr