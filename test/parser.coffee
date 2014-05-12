Parser = require '../lib/parser.coffee'
should = require('chai').should()

describe.only 'Parser', ->

  describe '#parse()', ->
    makeData = (rules) ->
      meta:
        resource: 'item'
      rules: rules

    it 'should parse file', ->
      parser = new Parser
      parsed = {}
      parsed = parser.parseFile __dirname + '/./parser/simple.yaml'


      parsed.should.eql {
        meta:
          resource: 'item'
        rules:
          query: [creator: 'return user.id;']
          create: [creator: 'return user.id;']
      }

    it 'should parse "either" rules', ->
      parsed = {}
      parser = new Parser

      parsed = parser.parseRule makeData
        query:
          either: [
             "this.creator is user.id"
             "user.role is 'admin'"
             "this.creator is 'guest'"
          ]


      parsed.should.eql {
        meta:
          resource: 'item'

        rules:
          query: [
            $or: [
              {creator: 'return user.id;'}
              {$where: "return user.role === 'admin';"}
              {creator: 'guest'}
            ]
          ]
      }

    it 'should parse numeric operator', ->
      parsed = {}
      parser = new Parser
      parsed = parser.parseRule makeData query: "this.value <= user.balance - 100"

      parsed.rules.query.should.eql [{
        value:
          $lte: 'return user.balance - 100;'
      }]

    it 'should parse numeric reversed operator', ->
      parsed = {}
      parser = new Parser
      parsed = parser.parseRule makeData query: "user.balance - 100 >= this.value"

      parsed.rules.query.should.eql [{
        value:
          $lte: 'return user.balance - 100;'
      }]

    it 'should skip to $where when both side has this.', ->
      parsed = {}
      parser = new Parser
      parsed = parser.parseRule makeData query:
        either: [
          "this.a > this.b"
          "this.d == @.e"
        ]

      parsed.rules.query[0].$or[0].should.has.property '$where'
      parsed.rules.query[0].$or[1].should.has.property '$where'


    it 'should parse complex rules', ->
      parser = new Parser
      parsed = {}
      should.not.throw ->
        parsed = parser.parseFile __dirname + '/./parser/complex.yaml'

      parsed.should.eql {
        meta:
          resource: 'item'
        rules:
          query: [
            $or: [
              {creator: 'return user.id;'}
              {$where: "return user.role === 'admin';"}
              {creator: 'guest'}
            ]
          ]

          create: [
            {creator: 'return user.id;'}
            {value:
                $lte: 'return user.balance - 100;'}
            {$or: [
              {name: 'return "Item by " + user.username;'}
              {$and: [
                {$where: "return user.role === 'admin';"}
                {name: 'return "Superior item by " + user.username;'}
              ]}
            ]}
          ]

          delete: [
            $or: [
              {creator: 'return user.id;'}
              {$where: "return user.role === 'admin';"}
            ]
          ]


      }


