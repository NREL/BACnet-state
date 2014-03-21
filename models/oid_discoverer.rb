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

class OidDiscoverer 
  include java.lang.Runnable
  def initialize(local_device, svc, num_devices_to_scan, time_to_stale, scanning_time, databus_sender = false)
    @local_device = local_device
    @sched_svc = svc
    @sender = databus_sender
    @num_devices_to_scan = num_devices_to_scan
    @time_to_stale = time_to_stale
    @scanning_time = scanning_time
  end

  # schedule fresh lookup of Oids for all known devices 
  # distribute start time randomly over scanning_time
  def run
    LoggerSingleton.logger.info "Starting run of OidDiscoverer"

    # make sure we grab the oldest devices first for priority scanning
    new_devices = KnownDevice.where(:refresh_oids_heartbeat => nil).asc(:discovered_heartbeat).limit(@num_devices_to_scan).entries
                                                                    
    LoggerSingleton.logger.info "#{new_devices.count} new devices found"

    # treat "num_devices_to_scan" as a total number, and prefer new_devices. This way we optimize and 
    # are always scanning as many as we can handle
    stale_devices = KnownDevice.where(:refresh_oids_heartbeat.lt => (Time.now - @time_to_stale)).asc(:refresh_oids_heartbeat).limit(@num_devices_to_scan - new_devices.size).entries

    LoggerSingleton.logger.info "#{DateTime.now} kicking oid discovery.  total new device count = #{KnownDevice.where(:refresh_oids_heartbeat => nil).count} and total stale device count = #{KnownDevice.where(:refresh_oids_heartbeat.lt => (Time.now - @time_to_stale)).count}"
    # note: rand is a uniform distribution provided by the mersenne twister which is thread specific
    # but this code runs in the main thread so the distribution should stay uniform 
    new_devices.each do |kd|
      # if kd.complete?
        delay = rand(@scanning_time.seconds)
        LoggerSingleton.logger.info "#{DateTime.now} scheduling oid lookup for device #{kd.instance_number} with delay of #{delay}"
        @sched_svc.schedule(DeviceOidLookup.new(kd, @local_device, @sender), delay, TimeUnit::SECONDS)
      # end
    end
    stale_devices.each do |kd|
      # if kd.complete?
        delay = rand(@scanning_time.seconds)
        LoggerSingleton.logger.info "#{DateTime.now} scheduling oid lookup for device #{kd.instance_number} with delay of #{delay}"
        @sched_svc.schedule(DeviceOidLookup.new(kd, @local_device, @sender), delay, TimeUnit::SECONDS)
      # end
    end
  end

end
