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

class SchedulablePoll 
  include java.lang.Runnable

  def initialize polltask, exec, known_device
    @polltask = polltask
    @exec = exec
    @known_device = known_device
  end

  def run
    begin
      LoggerSingleton.logger.info "\n\n#{DateTime.now} Starting polling for device #{@known_device.instance_number}"
      # recode that we are about to attempt polling
      @known_device.attempted_poll_heartbeat = Time.now
      @known_device.update
      # schedule on fixed threadpool with queue management
      # need to update mongo on successful completion
      # may also want to notify mongo of failed execution
      @exec.execute(@polltask)
    # rescue from exception so scheduled polling is not terminated
    rescue Exception => e
      LoggerSingleton.logger.error "\n\n#{DateTime.now} error running polling task: #{e.to_s}: #{e.backtrace.join("\n")}"
    end
  end
end
