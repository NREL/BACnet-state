require 'config/initialize.rb'
# TODO move into discoverer class
config = gov.nrel.bacnet.consumer.BACnet.parseOptions(ARGV)
bacnet = gov.nrel.bacnet.consumer.BACnet.new(config)
local_device = bacnet.getLocalDevice
KnownDevice.all.each do |kd|
  kd.discover_oids local_device
end
