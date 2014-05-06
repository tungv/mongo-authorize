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

    it 'should query items that match rules only', (done)->
      authorizr = new Authorizr({rulesRoot: __dirname + '/rules'})
      query = authorizr.query 'item', context
      query.exec (err, items)->
        should.exist items
        items.length.should.equal 9
        done()

    it 'should query items that match complex rule only', (done)->
      authorizr = new Authorizr({rulesRoot: __dirname + '/rules - complex'})
      query = authorizr.query 'item', context
      query.exec (err, items)->
        should.exist items
        items.length.should.equal 7
        done()

    it 'should not throw error on invalid context value', (done)->
      should.not.throw ()->
        authorizr = new Authorizr({rulesRoot: __dirname + '/rules - error handling'})
        query = authorizr.query 'item', context
        query.exec (err, items)->
          should.exist items
          items.length.should.equal 0
          done()
