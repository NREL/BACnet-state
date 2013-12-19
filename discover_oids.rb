require 'config/initialize.rb'
config = gov.nrel.bacnet.consumer.BACnet.parseOptions(ARGV)
bacnet = gov.nrel.bacnet.consumer.BACnet.new(config)
puts "config databusenabled: #{config.getDatabusEnabled}"
# our executor has queue management
executorPool = bacnet.getOurExec
local_device = bacnet.getLocalDevice
filters = bacnet.getFilters
writer = bacnet.getDatabusDataWriter
puts "writer: #{writer.class}"


KnownDevice.all.each do |kd|
  executorPool.execute(DeviceOidLookup.new(kd, local_device, filters, writer))
end
