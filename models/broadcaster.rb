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

class Broadcaster
  include java.lang.Runnable

  def initialize(min_id, max_id, local_device, broadcast_step = 1000)
    @min = min_id
    @max = max_id
    @local_device = local_device
    @next_broadcast_min = @min
    @broadcast_step = broadcast_step
    # set eventhandler on localdevice to manage sensors reporting in
    @local_device.getEventHandler().addListener(NewDeviceHandler.new);
  end

  # each run sends a whois over a shifting subinterval of the fulls scan range 
  def run
    if @next_broadcast_min > @max 
      LoggerSingleton.logger.info "#{DateTime.now} cancelling broadcast"
      # Any exception raised will cancel future scheduled executions.
      # Better to define a "execution completed" exception and throw that here.
      raise RuntimeException.new("broadcast completed")
    else
      broadcast_max = @next_broadcast_min + @broadcast_step - 1
      LoggerSingleton.logger.info "#{DateTime.now} broadcasting whois #{@next_broadcast_min} to #{broadcast_max}"
      broadcastWhoIs(@next_broadcast_min, broadcast_max)
      @next_broadcast_min = broadcast_max + 1
    end
  end

  def broadcastWhoIs min, max
    whois = WhoIsRequest.new(com.serotonin.bacnet4j.type.primitive.UnsignedInteger.new(min), com.serotonin.bacnet4j.type.primitive.UnsignedInteger.new(max))
    @local_device.sendBroadcast(whois);
  end
end