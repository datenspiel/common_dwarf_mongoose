require "#{process.cwd()}/lib/mixin"
require "#{process.cwd()}/lib/module"
require "#{process.cwd()}/lib/db"

# Require test libraries
vows    = require "vows"
should  = require "should"

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
)