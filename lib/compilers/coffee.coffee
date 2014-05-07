coffee = require 'coffee-script'

exports.compile = compile = (rules, output={})->
  #console.log 'coffee.compile'
  if typeof rules is 'string'
    try
      jsCode = coffee.compile 'return ' + rules, {bare:true}

      return jsCode.split('\n').join('')
    catch ex
      #logger.warn ex, rules
      undefined

  else
    keys = Object.keys rules
    output[key] = compile rules[key] for key in keys
    return output