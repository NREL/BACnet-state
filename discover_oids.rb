require 'config/initialize.rb'
config = gov.nrel.bacnet.consumer.BACnet.parseOptions(ARGV)
bacnet = gov.nrel.bacnet.consumer.BACnet.new(config)
# our executor has queue management
executorPool = bacnet.getOurExec
local_device = bacnet.getLocalDevice
filters = bacnet.getFilters
writer = bacnet.getDatabusDataWriter
sender = (writer.nil?) ? nil : writer.getSender

# first all known devices that have never updated oids


new_devices = KnownDevice.where(:refresh_oids_heartbeat => nil).entries
stale_devices = KnownDevice.where(:refresh_oids_heartbeat.lt => (Time.now - 1.week)).entries
puts "new device count = #{new_devices.count} and stale device count = #{stale_devices.count}"
new_devices.each do |kd|
  if kd.complete?
    executorPool.execute(DeviceOidLookup.new(kd, local_device, filters, sender))
  end
end
stale_devices.each do |kd|
  if kd.complete?
    executorPool.execute(DeviceOidLookup.new(kd, local_device, filters, sender))
  end
end
