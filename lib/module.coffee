# Global function to define a 'module'
module = (name) ->
  global[name] = global[name] or {}

module 'Mongoose'
module 'Mixin'
module 'Extensions'

# Monkey patching some globals.
String::['camelize'] = ()->
  (@.split('_').map (part) -> part[0].toUpperCase() + part[1..-1].toLowerCase()).join('')

String::['capitalize'] = ()->
  @[0].toUpperCase() + @[1..-1]

String::['pluralize'] = ()->
  "#{@.toLowerCase()}s"

exports.module = module