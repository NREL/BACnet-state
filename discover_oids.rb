require 'config/initialize.rb'
pool_size = 10
Oid.destroy_all
executorPool = Executors.newFixedThreadPool(10)
# partitions = Java::JavaUtil::ArrayList.new

# TODO move into discoverer class
config = gov.nrel.bacnet.consumer.BACnet.parseOptions(ARGV)
bacnet = gov.nrel.bacnet.consumer.BACnet.new(config)
local_device = bacnet.getLocalDevice
filters = bacnet.getFilters
KnownDevice.all.each do |kd|
  # does not save timeout
  executorPool.execute(DeviceOidLookup.new(kd, local_device, filters))

end
