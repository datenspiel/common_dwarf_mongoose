require "#{process.cwd()}/lib/mixin"
require "#{process.cwd()}/lib/module"
require "#{process.cwd()}/lib/db"

# Require test libraries
vows    = require "vows"
should  = require "should"
mongo   = require 'mongoose'

helper = require("#{process.cwd()}/tests/spec_helper.coffee").SpecHelper

class TestDbModel extends Mongoose.Base
  #@extend core.queryExtensibles
  alias: 'Blog'

  fields: 
    name  :  { type: String}
    age   :  { type: Number, min: 18, index: true }
  

exports.suite = vows.describe("database mongoose orm wrapper").addBatch(
  'given a class which inherits from OvuData.Base':
    'implements a blog model':
      topic:->
        klass = new TestDbModel()
        return klass
      'and sets alias to "blog"':
        'has #getBlog method':(klass)->
          klass.getBlog().should.be.defined
      'and gets name property':
        topic:(klass)->
          klass.set('name':"Max")
          klass.set('age':21)
          return klass
        'which equals after getting it':(klass)->
          #TestDbModel.find({ 'some.value': 5 })
          klass.get('name').should.equal "Max"
          klass.getName().should.equal "Max"
  'database':
    topic:->
      callback = @callback
      helper.setupDatabase(callback)
      return
    'connected to database':(err)->
      isUndefined = typeof err is "undefined"
      isUndefined.should.be.true
   'with a model':
    topic:->
      new TestDbModel()
    'save a new record':
      topic:(model)->
        model.set('name':'Jack')
        model.set('age': 34)
        model.save(@callback)
        return
      'succeeded':(doc)->
        doc.should.be.a('object')
      'is handable as Mongoose.Base':
        topic:(doc)->
          TestDbModel.becomesFrom(doc)
        'and is an instance of TestDbModel':(model)->
          model.should.be.an.instanceof(TestDbModel)
        '#getId()':(model)->
          model.getId().should.be.a('object')
    'updates':
      topic:->
        TestDbModel.update({name:'Jack', age: 34},{name: 'William'},{}, @callback)
        return
      'effects on one document':(err,numEffected)->
        numEffected.should.equal 1
    'finds an existing document':
      topic:->
        TestDbModel.find({name:'Jack'}, @callback)
        return
      'succeeded':(err,docs)->
        docs.length.should.equal 1
    'remove data from collection':
      topic:->
        TestDbModel.remove({},@callback)
        return
      'succeeded':(count)->
        isNotUndefined = typeof count isnt undefined
        isNotUndefined.should.be.true

)