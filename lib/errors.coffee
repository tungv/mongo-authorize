class InvalidFileError extends Error
  constructor: (path, message)->
    super "InvalidFileError: #{message} filePath: #{path}"



module.exports =
  InvalidFileError: InvalidFileError