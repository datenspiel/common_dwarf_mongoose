Mongo   = require "mongoose"
Schema  = Mongo.Schema

base = require "./mixin"

Mongoose.ObjectId = Schema.ObjectId
Mongoose.Mixed    = Schema.Types.Mixed

###
# This is the base class for all database namespaced 
  model classes.

  It generates a mongoose schema model from fields and
  wraps some base functionalities for mongoose. For full
  mongoose support use #getModel():

  measurementCount = MeasurementCount.getModel().where(...)

  To interact with the mongoose schema model in your model
  use the @model variable. 
  
  @author Daniel Schmidt, Datenspiel GmbH 
###

# A module with static methods for mongoose model
# integration.
mongooseClassExtensibles =
  # Delegates options to #find of mongoose model. 
  # Params are the same as listed here:
  # http://mongoosejs.com/docs/finding-documents.html
  find:(options...)->
    [query,fields,options,callback] = options[0..-1]
    m = new @
    m.getModel().find(query, fields, options, callback)
  
  # Delegates options to #remove of mongoose model. 
  # Params are the same as listed here:
  # http://mongoosejs.com/docs/finding-documents.html
  remove:(options...)->
    [conditions,callback] = options[0..-1]
    m = new @
    m.getModel().remove(conditions,callback)

  # Delegates options to #update of mongoose model.
  # Params are listed here:
  # http://mongoosejs.com/docs/updating-documents.html
  update:(options...)->
    [conditions,update,options,callback] = options[0..-1]
    m = new @
    m.getModel().update(conditions, update, options, callback)
    
# A module with instance methods for delegating to 
# a mongoose model instance.
mongooseInstanceExtensibles =
  # Delegates options to #save of mongoose model instance.
  # Param is usually a callback function with err as parameter.
  save:(options...)->
    #m = new model()
    cb = if options.length isnt 0 then options[0] else (err)-> throw err if err
    @.modelInstance.save(cb)

class Mongoose.Mixin extends base.Mixin
  @extend base.objectMethods

class Mongoose.Base extends Mongoose.Mixin
  # Extend class with static methods.
  @extend mongooseClassExtensibles
  # Extend class with instance methods.
  @include mongooseInstanceExtensibles

  # Alias is identifier which is used to create 
  # a collection with mongoose.
  alias: 'base'

  # fields are document definitions for mongo db. 
  # This is inspired by mongoid for ruby and ExtJS. 
  #
  # @example
  # fields: [
  #   {name: 'text', properties: {type: 'String'}},
  #   {name: 'temperature', properties: { type: 'double'}}
  # ]
  fields: {}

  ###
  This is simliar to ActiveRecord#becames. It takes an 
  mongoose document and casts this into a OvuData.Base instance. 

  @param  {Document} document The mongoose document which should be casted.
  @return {OvuData.Base} instance of OvuData.Base
  ###
  @becomesFrom:(document)->
    me = new @
    me.modelInstance = document
    return me

  #@scope:(scope_name, options)
  # @[scope_name] = 

  constructor:->
    @model = {}
    @setUpSchema()

  ###
  @private
  
  Initializes model schema. 
  (Delegates fields as attributes to createModel. Old implementation,
  should be untouched for now.)
  ###
  setUpSchema:=>
    @attributes = @fields
    @createModel(@attributes)


  ###
  @private
  Initializes mongoose model with a schema and a collection name
  which is pluralized from alias.
  Initializes also the building of the magic methods.
  ###
  createModel:(attributes)=>
    unless Mongoose.Mixin.isEmpty(@fields)
      modelSchema = new Schema(attributes)
      @model = Mongo.model(@alias, modelSchema, @alias.pluralize())
      @modelInstance = new @model()
      @buildMagicMethods()


  ###
  Sets a a value to the mongoose model.
  
  @param {Object} object An object which includes the value
  @example
    author = new Author()
    author.set('name': 'Jack Kerouac')
  ###
  set:(object)->
    for key,value of object
      @modelInstance[key] = value

  ###
  Get the value of the mongoose model attribute.

  @param  {String} field An attribute name which is defined in fields.
  @return {Any} The value of the mongoose model attribute associated to field.
  @example
    authorName = author.get('name') #=> Jack Kerouac
  ###
  get:(field)->
    @modelInstance[field]

  ###
  Returns the value of the document _id attribute.
  ###
  getId:->
    @modelInstance['_id']

  ###
  Returns the mongoose model (Notice: not the instance!)

  @return {Object} mongoose model.
  ###
  getModel:->
    @model

  ###
  @private
  
  Builds magic methods. 
  See Readme.mdown in this folder.
  ###
  buildMagicMethods:=>
    modelGetterSuffix = @alias.camelize()
    instance = @modelInstance
    @["get#{modelGetterSuffix}"] = ()->
      @model
    for key,value of @fields
      @initMethod(key,value)

  ###
  @private

  Creates a method to access an mongoose mode attribute 
  at Runtime

  @param {String} methodName - The method name to use which is also the attribute name. 
  ###
  initMethod:(methodName,schemaDefinition)=>
    try
      suffix = if typeof schemaDefinition.type() is 'boolean' then "is" else "get"
    catch e
      suffix = "get"

    @["#{suffix}#{methodName.camelize()}"] = ()->
      return @modelInstance[methodName]
