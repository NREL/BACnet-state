require 'java'
java_library = "../BACnet/build/bacnet/lib/"
Dir["#{java_library}\*.jar"].each { |jar| require jar }
def gov
  Java::Gov
end

require 'mongoid'
Mongoid.load!("config/mongoid.yml", :development)
Dir["models/\*.rb"].each { |rb| require rb }

java_import 'java.util.concurrent.TimeUnit'
java_import 'com.serotonin.bacnet4j.service.unconfirmed.WhoIsRequest'
java_import 'gov.nrel.bacnet.consumer.BACnet'
java_import 'gov.nrel.bacnet.consumer.PollDeviceTask'

