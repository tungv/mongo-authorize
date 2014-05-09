Authorizr = require '../lib/index.coffee'
should = require('chai').should()
#require './init-data.coffee'

describe 'Authorizr', ->
  describe '#readDir()', ->
    authorizr = null

    it 'should not throw any error while reading default dir', ->
      should.not.throw ()->
        authorizr = new Authorizr({rulesRoot: __dirname + '/rules - readdir'})

    it 'should have item with query and insert rules', ->
      should.exist authorizr.rules.item.query
      should.exist authorizr.rules.item.insert

  describe "matchPattern()", ->
    it 'should match user.* at the expression start', ->
      pattern = 'user.gender == "male"'
      matched = Authorizr.matchPatter pattern
      #console.log 'matched', matched
      matched[0].should.equal 'user.gender'

    it 'should match user.* in the middle of the expression', ->
      pattern = '"male" == user.gender'
      matched = Authorizr.matchPatter pattern
      #console.log 'matched', matched
      matched[0].should.equal 'user.gender'

    it 'should match user.*.* at the expression start', ->
      pattern = 'user.gender.abc == "male"'
      matched = Authorizr.matchPatter pattern
      #console.log 'matched', matched
      matched[0].should.equal 'user.gender.abc'

    it 'should match user.*.* in the middle of the expression', ->
      pattern = 'true && user.gender.abc == "male"'
      matched = Authorizr.matchPatter pattern
      #console.log 'matched', matched
      matched[0].should.equal 'user.gender.abc'

  describe "replaceMatched()", ->
    context =
      user:
        gender: 'male'
        names:
          first: 'first'
          last: 'last'
        age: 10

    it 'should replace user.* to the actual value from context', ->
      pattern = 'user.gender == "male"'
      rule = Authorizr.replaceMatched pattern, context
      rule.should.equal '"male" == "male"'

    it 'should replace user.*.* to the actual value from context', ->
      pattern = 'user.names.last == "male"'
      rule = Authorizr.replaceMatched pattern, context
      rule.should.equal '"last" == "male"'

    it 'should replace user.* to the actual Numeric value from context', ->
      pattern = 'user.age >= 5'
      rule = Authorizr.replaceMatched pattern, context
      rule.should.equal '10 >= 5'



  describe '#query()', ->
    context =
      user:
        gender: 'male'
        age: 25
        eyeColors: ['green', 'blue']

    it 'should query items that match rules only', (done)->
      authorizr = new Authorizr
      authorizr.applyRules {
        meta:
          resource: 'item'
        rules:
          query: 'user.gender is this.gender'
      }
      query = authorizr.makeQuery 'item', context
      query.exec (err, items)->
        should.exist items
        items.length.should.equal 9
        done()

    it 'should query items that match complex rule only', (done)->
      authorizr = new Authorizr
      authorizr.applyRules {
        meta:
          resource: 'item'
        rules:
          query: "user.age <= @age and user.gender is @gender"
      }
      query = authorizr.makeQuery 'item', context
      query.exec (err, items)->
        should.exist items
        items.length.should.equal 7
        done()

    it 'should not throw error on invalid context value', (done)->
      should.not.throw ()->
        authorizr = new Authorizr
        authorizr.applyRules {
          meta:
            resource: 'item'
          rules:
            query: "user.names.first is 'tung'"
        }
        query = authorizr.makeQuery 'item', context
        query.exec (err, items)->
          should.exist items
          items.length.should.equal 0
          done()

    it 'should handle "in" operator for data', (done)->
      authorizr = new Authorizr
      authorizr.applyRules {
        meta:
          resource: 'item'
        rules:
          query: 'this.eyeColor in ["green", "blue"]'
      }
      query = authorizr.makeQuery 'item', context
      query.exec (err, items)->
        should.exist items
        items.length.should.equal 12
        done()

    it 'should handle "in" operator for context', (done)->
      authorizr = new Authorizr
      authorizr.applyRules {
        meta:
          resource: 'item'
        rules:
          query: 'this.eyeColor in user.eyeColors'
      }
      query = authorizr.makeQuery 'item', context
      query.exec (err, items)->
        should.exist items
        items.length.should.equal 12
        done()

  describe '#optimize', ->
    authorizr = new Authorizr
    it 'should optimize this.a === "string"', ->
      actual = authorizr.optimize 'return this.a === "b"'
      actual.should.eql {
        a: 'b'
      }

    it 'should optimize this.a === number', ->
      actual = authorizr.optimize 'return this.a === 123.45'
      actual.should.eql {
        a: 123.45
      }

    it 'should optimize this.a === {object}', ->
      actual = authorizr.optimize 'return this.a === {"abc":{"nested":"object"}}'
      actual.should.eql {
        a: {
          abc: {
            nested: "object"
          }
        }
      }

    it 'should optimize "reversed" === this.a', ->
      actual = authorizr.optimize 'return "reversed" === this.a;'
      actual.should.eql {
        a: "reversed"
      }

    it 'should optimize "double equal" == this.a', ->
      actual = authorizr.optimize 'return "double equal" == this.a;'
      actual.should.eql {
        a: "double equal"
      }

    it 'should handle string with space in middle', ->
      actual = authorizr.optimize 'return "space in the middle" == this.a;'
      actual.should.eql {
        a: "space in the middle"
      }

      actual = authorizr.optimize 'return this.a === "space in the middle";'
      actual.should.eql {
        a: "space in the middle"
      }

    it 'should handle this.* on both sides', ->
      actual = authorizr.optimize 'return this.a === this.b;'
      actual.should.eql {
        $where: 'return this.a === this.b;'
      }

    it 'should handle no this.* on either side', ->
      actual = authorizr.optimize 'return "something" === "something else";'
      actual.should.eql {
        $where: 'return false;'
      }

      actual = authorizr.optimize 'return "something" === "something";'
      actual.should.eql {
        $where: 'return true;'
      }

    it 'should handle _id', ->
      actual = authorizr.optimize 'return this._id === "536c5f55d5fa6ede7d4f8636";'
      actual.should.eql {
        _id: "536c5f55d5fa6ede7d4f8636"
      }

    it 'should handle newline at the end', ->
      actual = authorizr.optimize 'return "something" === "something";\n\n\n'
      actual.should.eql {
        $where: 'return true;'
      }

    it 'should handle missing semicolon', ->
      actual = authorizr.optimize 'return "something" === "something"'
      actual.should.eql {
        $where: 'return true;'
      }

    it 'should handle missing semicolon and extra newline', ->
      actual = authorizr.optimize 'return "something" === "something"\n\n'
      actual.should.eql {
        $where: 'return true;'
      }



