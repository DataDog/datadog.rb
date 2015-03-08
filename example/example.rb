require 'datadog'
require 'pp'

d = Datadog.validate
puts d.valid?
