###
Spec/test for class system.

Tests mixin support by inherit from class Module.

@author Daniel Schmidt
###

# Require core. 
require "#{process.cwd()}/index"

# Require test libraries.
vows    = require 'vows'
should  = require('should')

# Modules to mix in to class later.
instanceProperties =
  mixinInstanceMethod: ->
classProperties =
  mixinClassMethod: ->

# Test class.
class MixinTest extends Mixin.Base
  @include instanceProperties
  @extend classProperties

exports.suite = vows.describe("oo inheritance architecture and core extensions").addBatch(
  'given a Module super class':
    'and a class which inherits and mixin instance methods':
      topic:->
        klass = new MixinTest()

        return klass
      'includes mixin functions':(klass)->
        has = klass.mixinInstanceMethod?
        has.should.be.true
    'and a class which inherits and mixin class methods':
      topic:->
        MixinTest
      'includes mixin functions':(klass)->
        has = klass.mixinClassMethod?
        has.should.be.true
  'extends Object':
    'with check if it is empty':
      'and when an object is empty':
        topic:->
          {}
        'returns true':(obj)->
          Mongoose.Mixin.isEmpty(obj).should.be.true
      'and when an object is not empty':
        topic:->
          {a:10}
        'returns false':(obj)->
          Mongoose.Mixin.isEmpty(obj).should.be.false
)
