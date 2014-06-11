yaml = require 'js-yaml'
fs = require 'fs'
errors = require './errors.coffee'
_ = require 'lodash'
Optimizer = require './optimizers/index.coffee'

log4js = require 'log4js'

query = require 'js-mongo-query'

module.exports = class Parser

  isAlwaysTrue = (rule)-> rule is true or rule.$where is true
  isAlwaysFalse = (rule)-> rule is false or rule.$where is false or rule.$all?.length == 0

  @replacer = replacer = (jsCode, context)->
    logger = log4js.getLogger 'replacer'
    logger.setLevel 'ERROR'

    logger.debug 'jsCode', jsCode

    ## match pattern with user.*
    matched = jsCode.match /(?=(^|\s*))(user\.\w+(\.\w*)*)/g
    logger.debug '  matched', matched

    matched?.forEach (match)->
      getter = new Function ['context'], "return context.#{match}"
      try
        value = JSON.stringify getter(context)
      catch
        value = 'undefined'

      logger.debug '    match', match, 'value', value
      jsCode = jsCode.split(match).join value or 'undefined'

    logger.debug '  after getter', jsCode

    unless jsCode.match /[ \(\[\=\>\<]this\./
      try
        original = jsCode
        fn = new Function [], jsCode
        jsCode = fn()
        logger.debug 'after eval\'ed', jsCode
      catch ex
        logger.warn 'cannot eval js script', jsCode, 'original', original

    return jsCode

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
    resourceObj = @parsed[resource] or
      meta:
        resource: resource
      rules: {}


    rulesObj = resourceObj.rules[name] or []

    optimizer = Optimizer.create language

    #console.log 'rules', typeof rules, rules

    @_recursiveNormalize rules, optimizer, rulesObj

    resourceObj.rules[name] = rulesObj
    @parsed[resource] = resourceObj

  _recursiveNormalize: (rules, optimizer, rulesObj, level=1)->
    #padding = ''
    if _.isArray rules.either
      #console.log(padding + 'either', arguments[0], arguments[2])
      $or = []
      rulesObj.push {$or}
      for rule in rules.either
        @_recursiveNormalize rule, optimizer, $or, level

    if _.isArray rules.all
      #console.log(padding + 'and', arguments[0], arguments[2])
      $and = []
      rulesObj.push {$and}
      for rule in rules.all
        @_recursiveNormalize rule, optimizer, $and, level

    else if _.isArray rules
      #console.log(padding + 'array', arguments[0], arguments[2])
      for rule in rules
        @_recursiveNormalize rule, optimizer, rulesObj, level

    else if _.isString rules
      #console.log(padding + 'string', arguments[0], arguments[2])
      rulesObj.push optimizer.optimize rules

    else if rules is true or rules is false
      #console.log(padding + 'boolean', arguments[0], arguments[2])
      rulesObj.push rules

  applyContext: (resource, action, context)->
    logger = log4js.getLogger 'applyContext'
    logger.setLevel 'ERROR'

    logger.trace 'resource', resource
    logger.trace 'action', action
    logger.trace 'context', context

    root = _.cloneDeep @parsed[resource]?.rules
    cloned = root?[action]

    return unless cloned

    root = {$and: cloned}
    logger.trace 'before root', root

    #for rule, index in cloned
    @_recursiveApplyContext root, '$and', cloned, context, '$and'

    if root.$and?.length == 1
      return root.$and[0]

    logger.trace 'after root', root

    return root


  _recursiveApplyContext: (root, property, value, context, parentLogic='$and')->
    logger = log4js.getLogger 'r-applyContext'
    logger.setLevel 'ERROR'

    if typeof value is 'string'
      logger.debug 'string', property, ':', value
      #console.log 'root[property]', property, root[property]
      root[property] = replacer value, context
      #logger.debug 'parentLogic', parentLogic

    else if _.isArray value
      ## inside an $or or $and
      logic = parentLogic

      logger.debug "#{logic} array"

      for subValue, index in value
        @_recursiveApplyContext value, index, subValue, context, parentLogic

      ## handle always-true-$or and always-false-$and
      if logic is '$or'
        ## in case of $or, if one of the rules is true then $or will always be true

        ## testing for always-true
        alwaysTrue = value.some isAlwaysTrue
        if alwaysTrue
          logger.debug 'always true', value
          delete root[property]
          return

        ## remove always-false rules
        value = _.reject value, isAlwaysFalse
        value = [$all:[]] if value.length is 0


      if logic is '$and'
        logger.debug 'value', value
        logger.debug 'root', root
        logger.debug 'property', property

        ## testing for an always-false
        alwaysFalse = value.some isAlwaysFalse
        if (alwaysFalse)
          delete root[property]
          root.$all = []
          return

        ## remove always-true rules
        value = _.reject value, isAlwaysTrue

      logger.debug "#{logic} array end"

      if value.length > 1
        root[property] = value
      else if value.length == 1
        logger.debug 'array.length == 1'
        logger.debug '  logic', logic
        logger.debug '  property', property
        logger.debug '  value[0]', value[0]
        delete root[property]
        _.extend root, value[0]
      else
        delete root[property]

    else
      ## inside a mongodb operator ($gle, $not...)
      for key, subValue of value
        @_recursiveApplyContext value, key, subValue, context, key

  isAllowed: (resource, ruleName, model, context)->
    logger = log4js.getLogger 'isAllowed'
    logger.setLevel 'ERROR'

    logger.trace 'resource', resource
    logger.trace 'ruleName', ruleName
    logger.trace 'context', context

    rules = @applyContext resource, ruleName, context
    logger.debug 'rules', rules
    @validateModel model, rules

  createAllowed: (resource, model, context)->
    @isAllowed resource, 'create', model, context

  validateModel: (model, rules)->
    logger = log4js.getLogger 'validateModel'
    return query model, rules

