class InvalidFileError extends Error
  constructor: (path, message)->
    super "InvalidFileError: #{message} filePath: #{path}"

class InvalidRuleError extends Error
  constructor: (data, message)->
    super "InvalidRuleError: #{message} rules: #{data}"

module.exports =
  InvalidFileError: InvalidFileError
  InvalidRuleError: InvalidRuleError