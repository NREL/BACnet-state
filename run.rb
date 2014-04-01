# Copyright (C) 2013, Alliance for Sustainable Energy
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################

require 'config/initialize.rb'
require 'active_support' #for time utilities

config = BACnet.parseOptions(ARGV)
bacnet = BACnet.new(config)
local_device = bacnet.getLocalDevice
KnownDevice.set_local_device(local_device)
our_exec = bacnet.getOurExec
scheduler = our_exec.getScheduledSvc
writer = bacnet.getDatabusDataWriter
sender = (writer.nil?) ? nil : writer.getSender

#calc seconds to midnight (UTC or local)
cur_time = Time.now.in_time_zone('Mountain Time (US & Canada)')
midnight = cur_time.tomorrow.at_midnight
time_to_midnight = midnight - cur_time

aggressive_scanning = false

if !aggressive_scanning
  # 'conservative' daily scanning of network
  num_devices_to_scan = 20
  time_to_device_stale = 1.day
  device_scanning_time = 1.minute
  time_between_oid_scans = 10.minute
  delay_to_start_scanning = time_to_midnight
  time_between_scans = 1.day
  new_device_poll_time = 30.minute
else
  # 'aggressive' for testing
  num_devices_to_scan = 20
  time_to_device_stale = 10.minute
  device_scanning_time = 2.minute
  time_between_oid_scans = 4.minute
  delay_to_start_scanning = 0
  time_between_scans = 10.minute
  new_device_poll_time = 10.minute
end

# intialize a discoverer, which coordinates one complete broadcast over interval (min,max)
discoverer = Discoverer.new(config.getMinId, config.getMaxId, local_device, scheduler)

##### DEVICE SCANNING ########
LoggerSingleton.logger.info "scheduling device discovery scans to run every #{time_between_scans.to_s} seconds.  First scan at #{(cur_time + delay_to_start_scanning).to_s}"
scheduler.scheduleAtFixedRate(discoverer, delay_to_start_scanning.to_i, time_between_scans.to_i, TimeUnit::SECONDS)

##### OID LOOKUPS ######
oid_discoverer = OidDiscoverer.new(local_device, scheduler, num_devices_to_scan, time_to_device_stale, device_scanning_time, sender)
LoggerSingleton.logger.info "scheduling OID lookup to every #{time_between_oid_scans.to_s} seconds."
scheduler.scheduleAtFixedRate(oid_discoverer, 30, time_between_oid_scans.to_i, TimeUnit::SECONDS)
# puts "scheduling OID lookup to run once a day 2 hours after midnight"
# scheduler.scheduleAtFixedRate(oid_discoverer, seconds_to_midnight + 60*60*2, 60*60*24, TimeUnit::SECONDS)

##### POLLING #####
LoggerSingleton.logger.info "kicking off polling"
KnownDevice.all.each do |kd|
  if kd.complete?
    remote_device = kd.get_remote_device
    polltask = PollDeviceTask.new(remote_device,local_device,bacnet.getDefaultWriters,our_exec.getRecorderSvc)
    oids = kd.oids.where(:poll_interval_seconds.gt => -1).entries
    if oids.count > 1 # todo  change to > 0 when java bug polling devices with one oid is fixed
      oids.each do |o| 
        polltask.addInterval(o.get_object_identifier, o.poll_interval_seconds) 
      end
      polltask.setCachedOids(oids.map{|o| o.get_object_identifier})
      delay = polltask.init()
      LoggerSingleton.logger.info "initializing polling of device #{kd.instance_number} with #{oids.count} pollable oids. interval = #{delay.getInterval} and initial delay = #{delay.getDelay}"
      pollone = SchedulablePoll.new(polltask, our_exec, kd)
      scheduler.scheduleAtFixedRate(pollone, delay.getDelay, delay.getInterval, TimeUnit::SECONDS)
    end
  end
end

new_polling_scheduler = NewDevicePollScheduler.new(local_device, our_exec, bacnet.getDefaultWriters)
scheduler.scheduleAtFixedRate(new_polling_scheduler, 60, new_device_poll_time.to_i, TimeUnit::SECONDS)
