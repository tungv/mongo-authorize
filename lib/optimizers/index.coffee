
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

  constructor: ()->
    @replacers = []

  placeholder: (context, property, jsCode)->
    ## not used yet
    ## if it has this, skip eval'ing
    if jsCode.match /this/ then return jsCode

    matched = jsCode.match /(?=(^|\s*))(user\.\w+(\.\w*)*)/g

    replacer = (context)->
      rule = jsCode
      matched?.forEach (match)->
        getter = new Function ['context'], "return context.#{match}"
        try
          value = getter(context)
        catch
          value = 'undefined'

        rule = rule.split(match).join(JSON.stringify(value))

      return rule

    @replacers.push replacer

class Optimizer.CoffeeScript extends Optimizer
  coffee = require 'coffee-script'

  constructor: -> super

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
    matched = rule.match /^\s*([^=]+)\s?(==|!=|\sis\s|\sisnt\s|\sin\s|<=?|>=?)([^;]+)\s*(;\n*)?$/
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
            when 'in'
              if !swap
                ## this.value in array
                obj[path] = $in:value
              else
                ## value in this.array
                obj[path] = value

        catch ex
          console.error 'ex', ex


        return obj


    else
      #console.log 'not matched', matched

    value = Optimizer.getter parse rule
    return value if typeof value is 'boolean'
    return {$where: value}


module.exports = Optimizer