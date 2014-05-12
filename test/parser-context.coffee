Parser = require '../lib/parser.coffee'
should = require('chai').should()

describe.only 'Parser', ->
  makeData = (rules) ->
    meta:
      resource: 'item'
    rules: rules

  describe '#applyContext()', ->

    it 'should handle flat one-level rules', ->
      parser = new Parser
      parsed = {}
      parsed = parser.parseRule makeData
        query: 'this.creator is user.id'
        create: 'user.id == @creator'

      parsed