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
