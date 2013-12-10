require 'java'
# path to java library
java_library = "../build/bacnet/lib/"
Dir["#{java_library}\*.jar"].each { |jar| require jar }
def gov
  Java::Gov
end
require 'mongoid'
Mongoid.load!("config/mongoid.yml", :development)
Dir["models/\*.rb"].each { |rb| require rb }