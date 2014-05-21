Parser = require '../lib/parser.coffee'
should = require('chai').should()

describe 'Parser', ->

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

    it 'should optimize this.a == "string"', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: 'this.a == "b"'
      actual.rules.query.should.eql [{
        a: 'b'
      }]

    it 'should optimize this.a == number', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: 'this.a == 123.45'
      actual.rules.query.should.eql [{
        a: 123.45
      }]

    it 'should optimize this.a == {object}', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: 'this.a == {"abc":{"nested":"object"}}'
      actual.rules.query.should.eql [{
        a: {
          abc: {
            nested: "object"
          }
        }
      }]

    it 'should optimize "reversed" == this.a', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: '"reversed" == this.a'
      actual.rules.query.should.eql [{
        a: "reversed"
      }]

    it 'should handle string with space in middle of the first part', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: '"space in the middle" == this.a'
      actual.rules.query.should.eql [{
        a: "space in the middle"
      }]

    it 'should handle string with space in middle of the last parts', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: 'this.a == "space in the middle";'
      actual.rules.query.should.eql [{
        a: "space in the middle"
      }]

    it 'should handle this.* on both sides', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: 'this.a == this.b'
      actual.rules.query.should.eql [{
        $where: 'return this.a === this.b;'
      }]

    it 'should handle no this.* on either side', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: '"something" == "something else";'
      actual.rules.query.should.eql [false]

      parser = new Parser 
      actual = parser.parseRule makeData query: '"something" == "something";'
      actual.rules.query.should.eql [true]

    it 'should handle _id', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: 'this._id == "536c5f55d5fa6ede7d4f8636";'
      actual.rules.query.should.eql [{
        _id: "536c5f55d5fa6ede7d4f8636"
      }]

    it 'should handle newline at the end', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: '"something" == "something";\n\n\n'
      actual.rules.query.should.eql [true]

    it 'should handle missing semicolon', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: '"something" == "something"'
      actual.rules.query.should.eql [true]

    it 'should handle missing semicolon and extra newline', ->
      parser = new Parser 
      actual = parser.parseRule makeData query: '"something" == "something"\n\n'
      actual.rules.query.should.eql [true]

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
      parser = new Parser
      parsed = parser.parseRule makeData query: "user.balance - 100 >= this.value"

      parsed.rules.query.should.eql [{
        value:
          $lte: 'return user.balance - 100;'
      }]

    it 'should optimize "not" rule with !=', ->
      parser = new Parser

      parsed = parser.parseRule makeData query: "user.balance != this.value"
      parsed.rules.query.should.eql [{
        value:
          $not: 'return user.balance;'
      }]

    it 'should optimize "not" rule with isnt', ->
      parser = new Parser
      parsed = parser.parseRule makeData query: "user.balance isnt this.value"
      parsed.rules.query.should.eql [{
        value:
          $not: 'return user.balance;'
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

    it 'should parse shortcut false rule', ()->
      parser = new Parser
      parsed = parser.parseRule makeData query:false

      parsed.rules.query.should.eql [false]

    it 'should parse shortcut true rule', ()->
      parser = new Parser
      parsed = parser.parseRule makeData query:true

      parsed.rules.query.should.eql [true]



