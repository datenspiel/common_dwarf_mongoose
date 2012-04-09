inflector = require "inflection"
Mongo     = require "mongoose"
Schema    = Mongo.Schema

require "./mixin"

Mongoose.ObjectId = Schema.ObjectId
Mongoose.Mixed    = Schema.Types.Mixed

# Merges properties from config into object if
# config is an object.
#
# This is heavily inspired by ExtJS.
# 
# Return the object with merged properties. 
apply=(object,another)->
  if object? and another? and typeof another is 'object'
    for key of another
      object[key] = another[key]

  return object


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
    
  # Delegates options to #findById of mongoose model.
  # Params are listed here:
  # http://mongoosejs.com/docs/finding-documents.html
  findById:(options...)->
    [id,callback] = options[0..-1]
    m = new @
    m.getModel().findById(id,callback)

  # Delegates options to #findOne of mongoose model.
  # Params are listed here:
  # http://mongoosejs.com/docs/finding-documents.html
  findByOne:(options...)->
    [query,callback] = options[0..-1]
    m = new @
    m.getModel().findByOne(query,callback)

  # Delegates options to #count of mongoose model.
  # Params are listed here:
  # http://mongoosejs.com/docs/finding-documents.html
  count:(options...)->
    [query,callback] = options[0..-1]
    m = new @
    m.getModel().count(query,callback)

  # Workaround to get #where and its method chaining 
  # working for Mongoose.Base.
  # Usage it like:
  #
  # Actor.forWhere()
  # .where('age').gte(25)
  # .where('tags').in(['movie', 'music', 'art'])
  # . #  select('name', 'age', 'tags')
  # .skip(20)
  # .limit(10)
  # .asc('age')
  # .slaveOk()
  # .hint({ age: 1, name: 1 })
  # .run(callback)
  forWhere:->
    return (new @).getModel()

# A module with instance methods for delegating to 
# a mongoose model instance.
mongooseInstanceExtensibles =
  # Delegates options to #save of mongoose model instance.
  # Param is usually a callback function with err as parameter.
  save:(options...)->
    #m = new model()
    cb = if options.length isnt 0 then options[0] else (err)-> throw err if err
    @.modelInstance.save(cb)

class Mongoose.Mixin extends Mixin.Base
  @extend Extensions.objectMethods

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

  # plugins is a list of plugins, which should used
  # within the models schema.
  #
  # @example
  # plugins: [
  #   {plugin: mongooseAuth, config: { facebook:true }} 
  # ]
  #
  # or
  # plugins: 
  #   plugin: mongooseAuth, config: {facebook:true}
  plugins: {} 

  ###
  This is simliar to ActiveRecord#becames. It takes an 
  mongoose document and casts this into a OvuData.Base instance. 

  @param  {Document} document The mongoose document which should be casted.
  @return {OvuData.Base} instance of OvuData.Base
  ###
  @becomesFrom:(document)->
    me = new @
    me.modelInstance = document
    me.buildAttributes()
    return me

  #@scope:(scope_name, options)
  # @[scope_name] = 

  constructor:->
    @attributes = {}
    @model = {}
    @setUpSchema()
    #@buildAttributes()

  ###
  @private
  
  Initializes model schema. 
  (Delegates fields as attributes to createModel. Old implementation,
  should be untouched for now.)
  ###
  setUpSchema:=>
    @createModel(@fields)

  ###
  @private
  Initializes mongoose model with a schema and a collection name
  which is pluralized from alias.
  Initializes also the building of the magic methods.
  ###
  createModel:(attributes)=>
    unless Mongoose.Mixin.isEmpty(@fields)
      @modelSchema = new Schema(attributes)
      @addPlugins()
      @model = Mongo.model(@alias, @modelSchema, inflector.pluralize(@alias))
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
      @updateAttributes(key)

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
  Returns the attributes as JSON.
  ###
  toJSON:->
    JSON.stringify(@attributes)

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

  Updates the attributes property with the value of key.
  ###
  updateAttributes:(key)->
    #console.log "key is #{key}"
    #console.log @modelInstance
    attr = {}
    attr[key] = @modelInstance[key]
    @attributes = apply(@attributes,attr) if attr[key]?
    
  ###
  @private 

  Build attributes property with existing data properties.
  ###
  buildAttributes:->
    @updateAttributes(key) for key,value of @fields
     

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

  addPlugins:->
    if @plugins instanceof Array
      for plugin in @plugins
        pluginConfig = if plugin.config? then plugin.config else {}
        @pluginToSchema(plugin,pluginConfig)
    else
      unless Mongoose.Mixin.isEmpty(@plugins)
        pluginConfig = if @plugins.config? then @plugins.config else {}
        @pluginToSchema(@plugins.plugin, pluginConfig)

  ###
  @private
  ###
  pluginToSchema:(plugin,config)->
    @modelSchema.plugin(plugin, config)