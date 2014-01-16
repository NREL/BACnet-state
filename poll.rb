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
# TODO replace executor managed by bacnet instance

config = gov.nrel.bacnet.consumer.BACnet.parseOptions(ARGV)
bacnet = gov.nrel.bacnet.consumer.BACnet.new(config)
exec = bacnet.getOurExec
local_device = bacnet.getLocalDevice
kd = KnownDevice.first
# KnownDevice.all.each do |kd|
  remote_device = kd.get_remote_device

  polltask = gov.nrel.bacnet.consumer.PollDeviceTask.new(remote_device,local_device,bacnet.getDefaultWriters)

  oids = kd.oids.where(:poll_interval_seconds.gt => -1).entries
  # this will be replaced when we save the polling offset on the known device object rather than
  # calculating it each time polling is kicked off
  oids.each do |o| 
    polltask.addInterval(o.get_object_identifier, o.poll_interval_seconds) 
  end

  puts "kd #{kd.instance_number} with #{oids.count} pollable oids"
  polltask.setCachedOids(oids.map{|o| o.get_object_identifier})
  delay = polltask.init()
  puts "interval = #{delay.getInterval} and initial delay = #{delay.getDelay}"

  pollone = SchedulablePoll.new(polltask,exec)
  # exec.getScheduledSvc.scheduleWithFixedDelay(pollone, delay.getDelay, delay.getInterval, TimeUnit::SECONDS)
  exec.getScheduledSvc.scheduleWithFixedDelay(pollone, 0, 20, TimeUnit::SECONDS)
# end

# also update polling heartbeat