Parser = require '../lib/parser.coffee'
should = require('chai').should()

describe 'Parser', ->
  describe "replaceMatched()", ->
    context =
      user:
        gender: 'male'
        names:
          first: 'first'
          last: 'last'
        age: 10

    it 'should replace user.* to the actual value from context', ->
      pattern = 'return user.gender === "male"'
      rule = Parser.replacer pattern, context
      rule.should.equal true

    it 'should replace user.*.* to the actual value from context', ->
      pattern = 'return user.names.last === "male";'
      rule = Parser.replacer pattern, context
      rule.should.equal false

    it 'should replace user.* to the actual Numeric value from context', ->
      pattern = 'return user.age >= 5;'
      rule = Parser.replacer pattern, context
      rule.should.equal true

    it 'should skip eval if pattern has this.', ->
      pattern = 'return user.age >= this.age;'
      rule = Parser.replacer pattern, context
      rule.should.equal 'return 10 >= this.age;'