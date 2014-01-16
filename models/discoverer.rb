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

class Discoverer 
  include java.lang.Runnable
  def initialize(min_id, max_id, local_device, svc, step = 100, delay = 0, interval_in_secs = 1)
    @min = min_id
    @max = max_id
    @local_device = local_device
    @sched_svc = svc
    @step = step
    @interval_in_secs = interval_in_secs
  end

  # schedule one complete scan of devices from @min to @max.  
  # by scheduling staggered whois broadcasts over subintervals.
  def run
    broadcaster = Broadcaster.new(@min, @max, @local_device, @step)
    LoggerSingleton.logger.info "#{DateTime.now} starting broadcast of range #{@min} to #{@max} in steps of #{@step} at interval of #{@interval_in_secs}"
    @sched_svc.scheduleAtFixedRate(broadcaster, @delay, @interval_in_secs, TimeUnit::SECONDS)
  end

end
