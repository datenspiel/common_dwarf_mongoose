###
Add mixin support with a Module class implementation
###
moduleKeywords = ['extended', 'included']

class Mixin
  @extend:(obj)->
    for key,value of obj when key not in moduleKeywords
      @[key] = value

    obj.extended?.apply(@)
    @

  @include:(obj)->
    for key,value of obj when key not in moduleKeywords
      @::[key] = value

    obj.included?.apply(@)
    @

objectMethods =
  # Checks if an object is empty by
  # checking if any property is included.
  #
  # Returns true if empty otherwise false
  isEmpty:(obj)->
    for property of obj
      return false if obj.hasOwnProperty(property)
    return true

exports.Mixin         = Mixin
exports.objectMethods = objectMethods