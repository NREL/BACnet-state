require 'config/initialize.rb'
# TODO replace executor managed by bacnet instance
executorPool = Executors.newScheduledThreadPool(1)

config = gov.nrel.bacnet.consumer.BACnet.parseOptions(ARGV)
bacnet = gov.nrel.bacnet.consumer.BACnet.new(config)
local_device = bacnet.getLocalDevice
kd = KnownDevice.where(:instance_number => 9800).first
remote_device = kd.get_remote_device

# set up polldevicetask.  this can certainly be improved
pollone = gov.nrel.bacnet.consumer.PollDeviceTask.new(remote_device,local_device,executorPool,bacnet.getDefaultWriters)
oids = kd.oids.where(:poll_interval_seconds.gt => -1).entries
# this will be replaced when we save the polling offset on the known device object rather than
# calculating it each time polling is kicked off
oids.each do |o| 
  pollone.addInterval(o.get_object_identifier, o.poll_interval_seconds) 
end

puts "kd #{kd.instance_number} with #{oids.count} pollable oids"
pollone.setCachedOids(oids.map{|o| o.get_object_identifier})
delay = pollone.init()
puts "interval = #{delay.getInterval} and initial delay = #{delay.getDelay}"
# executorPool.scheduleWithFixedDelay(pollone, delay.getDelay, delay.getInterval, TimeUnit::SECONDS)
executorPool.scheduleWithFixedDelay(pollone, 0, 20, TimeUnit::SECONDS)
