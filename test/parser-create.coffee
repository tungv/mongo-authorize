Parser = require '../lib/parser.coffee'
should = require('chai').should()

describe 'Parser', ->

  describe '#createAllowed()', ->
    makeData = (createRule)->
      meta:
        resource: 'item'
      rules:
        create: createRule

    it 'should allow valid object to be created', ->
      rules = [
        "this.creator is user.id"
        "this.value <= user.balance"
      ]

      context =
        user:
          id: '123'
          balance: 1000

      item =
        creator: '123'
        value: 900

      parser = new Parser
      parser.parseRule makeData rules

      parser.createAllowed('item', item, context).should.be.true