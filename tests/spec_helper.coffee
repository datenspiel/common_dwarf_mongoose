mongo = require 'mongoose'

config =
  test:
    host:"0.0.0.0",
    database:"cm_test"
    port: 27017

class SpecHelper

  @setupDatabase : (callback)->
    mongo.connect("mongodb://#{config.test.host}/#{config.test.database}",callback)

exports.SpecHelper = SpecHelper