require 'config/initialize.rb'

# TODO move into discoverer class
config = gov.nrel.bacnet.consumer.BACnet.parseOptions(ARGV)
bacnet = gov.nrel.bacnet.consumer.BACnet.new(config)
$local_device = bacnet.getLocalDevice
discoverer = Discoverer.new(config.getMinId, config.getMaxId, $local_device)
discoverer.broadcastWhoIs 100

