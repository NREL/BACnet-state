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

class NewDevicePollScheduler 
  include java.lang.Runnable

  def initialize local_device, our_exec, writers
    @local_device = local_device
    @exec = our_exec
    @writers = writers
  end

  def run
    begin
      # Look for any devices that we have never attempted to poll (newly discovered) and schedule to poll 
      new_devices = KnownDevice.where(:attempted_poll_heartbeat => nil, :refresh_oids_heartbeat.ne => nil).entries
      LoggerSingleton.logger.info "#{DateTime.now} initializing polling of #{new_devices.count} recently discovered devices"
      new_devices.each do |kd| 
        if kd.complete?
          remote_device = kd.get_remote_device
          polltask = PollDeviceTask.new(remote_device,@local_device,@writers,@exec.getRecorderSvc)
          oids = kd.oids.where(:poll_interval_seconds.gt => -1).entries
          oids.each do |o| 
            polltask.addInterval(o.get_object_identifier, o.poll_interval_seconds) 
          end
          polltask.setCachedOids(oids.map{|o| o.get_object_identifier})
          delay = polltask.init()
          LoggerSingleton.logger.info "#{DateTime.now} initializing polling of recently discovered device #{kd.instance_number} with #{oids.count} pollable oids. interval = #{delay.getInterval} and initial delay = #{delay.getDelay}"
          pollone = SchedulablePoll.new(polltask, @exec, kd)
          @exec.getScheduledSvc.scheduleAtFixedRate(pollone, delay.getDelay, delay.getInterval, TimeUnit::SECONDS)
        end
      end
    rescue Exception => e
      LoggerSingleton.logger.error "#{DateTime.now} error scheduling new poll schedulers: #{e.to_s}: #{e.backtrace.join("\n")}"
    end
  end
end
