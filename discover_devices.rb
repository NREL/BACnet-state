require 'config/initialize.rb'

config = gov.nrel.bacnet.consumer.BACnet.parseOptions(ARGV)
bacnet = gov.nrel.bacnet.consumer.BACnet.new(config)
local_device = bacnet.getLocalDevice
KnownDevice.set_local_device(local_device)
discoverer = Discoverer.new(config.getMinId, config.getMaxId, local_device, bacnet.getOurExec.getScheduledSvc)
discoverer.run

