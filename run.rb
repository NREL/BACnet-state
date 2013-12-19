require 'config/initialize.rb'
require 'active_support' #for time utilities

config = BACnet.parseOptions(ARGV)
bacnet = BACnet.new(config)
local_device = bacnet.getLocalDevice
KnownDevice.set_local_device(local_device)
our_exec = bacnet.getOurExec
scheduler = our_exec.getScheduledSvc
filters = bacnet.getFilters
writer = bacnet.getDatabusDataWriter

# intialize a discoverer, which coordinates one complete broadcast over interval (min,max)
discoverer = Discoverer.new(config.getMinId, config.getMaxId, local_device, scheduler)

##### DEVICE SCANNING ########
#calc seconds to midnight (UTC or local)
cur_time = Time.now.in_time_zone('Mountain Time (US & Canada)')
midnight = cur_time.tomorrow.at_midnight
seconds_to_midnight = midnight.to_i - cur_time.to_i
puts "scheduling device discovery scans to run once a day at midnight.  First scan in #{seconds_to_midnight} seconds"
scheduler.scheduleAtFixedRate(discoverer, seconds_to_midnight, 60*60*24, TimeUnit::SECONDS)

##### OID LOOKUPS ######
oid_discoverer = OidDiscoverer.new(local_device, filters, scheduler, writer)
puts "scheduling OID lookup to run once a day 2 hours after midnight"
scheduler.scheduleAtFixedRate(oid_discoverer, seconds_to_midnight + 60*60*2, 60*60*24, TimeUnit::SECONDS)

##### POLLING #####
puts "kicking off polling"
KnownDevice.all.each do |kd|
  remote_device = kd.get_remote_device
  polltask = PollDeviceTask.new(remote_device,local_device,bacnet.getDefaultWriters)
  oids = kd.oids.where(:poll_interval_seconds.gt => -1).entries
  oids.each do |o| 
    polltask.addInterval(o.get_object_identifier, o.poll_interval_seconds) 
  end
  polltask.setCachedOids(oids.map{|o| o.get_object_identifier})
  delay = polltask.init()
  puts "initializing polling of device #{kd.instance_number} with #{oids.count} pollable oids. interval = #{delay.getInterval} and initial delay = #{delay.getDelay}"
  pollone = SchedulablePoll.new(polltask, our_exec)
  scheduler.scheduleAtFixedRate(pollone, delay.getDelay, delay.getInterval, TimeUnit::SECONDS)
end