Parser = require '../lib/parser.coffee'
should = require('chai').should()

describe 'Parser', ->
  makeData = (rules) ->
    meta:
      resource: 'item'
    rules: rules

  describe '#applyContext()', ->
    context =
      user:
        id: "123"

    it 'should handle flat one-level rules', ->
      parser = new Parser

      parser.parseRule makeData
        query: 'this.creator is user.id'
        create: 'user.id == @creator'

      parser.applyContext('item', 'query', context).should.eql {creator: '123'}
      parser.applyContext('item', 'create', context).should.eql {creator: '123'}

    it 'should handle nested rule', ->
      parser = new Parser
      parser.parseRule makeData
        query: [
          'this.creator is user.id'
          'this.balance >= 50'
        ]

      parser.applyContext('item', 'query', context).should.eql {
        $and: [
          {creator: '123'}
          {balance: $gte:50}
        ]
      }

    it 'should handle always true in $and rule', ->
      parser = new Parser
      parser.parseRule makeData
        query: [
          'user.id is "123"'
          'this.id is user.id'
        ]

      parser.applyContext('item', 'query', context).should.eql {
        id: '123'
      }

    it 'should handle always false in $and rule', ->
      parser = new Parser
      parser.parseRule makeData
        query: [
          'user.id is "1234"'
          'this.id is user.id'
        ]

      parser.applyContext('item', 'query', context).should.eql {$all:[]}

    it 'should handle always true in $or rule', ->
      parser = new Parser
      parser.parseRule makeData
        query: [
          either: [
            'user.id is "123"'
            'this.id is user.id'
          ]
        ]

      parser.applyContext('item', 'query', context).should.eql { }

    it 'should handle always false in $or rule', ->
      parser = new Parser
      parser.parseRule makeData
        query: [
          either: [
            'user.id is "1234"'
            'this.id is user.id'
          ]
        ]

      parser.applyContext('item', 'query', context).should.eql {
        id: '123'
      }

    it 'should handle nested always true/false in $or/$and', ->
      parser = new Parser
      parser.parseRule makeData
        query: [
          either: [
            'true'
            'false'
            'this.age >= user.age'
          ]
          either: [
            'false'
            'this.id is user.id'
          ]
        ]

      parser.applyContext('item', 'query', context).should.eql {
        id: '123'
      }

    it "should handle shortcut false rule", ->
      parser = new Parser
      parser.parseRule makeData query:false
      parser.applyContext('item', 'query', context).should.eql {$all:[]}

    it "should handle all false in $or", ->
      parser = new Parser
      parser.parseRule makeData
        query: [
          '1 is 2'
          '2 is 3'
          '3 is 1'
        ]
      parser.applyContext('item', 'query', context).should.eql {$all:[]}


