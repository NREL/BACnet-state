require 'config/initialize.rb'
config = gov.nrel.bacnet.consumer.BACnet.parseOptions(ARGV)
bacnet = gov.nrel.bacnet.consumer.BACnet.new(config)
filters = bacnet.getFilters
KnownDevice.all.each do |kd|
  remote_device = kd.get_remote_device
  kd.oids.all.each do |o|
    interval = filters.getPollingInterval(remote_device, o.get_object_identifier)
    o.update_poll_interval(interval)
  end
end
