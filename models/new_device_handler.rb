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

# require 'java'
# require '../../../src/main/ruby/logger_singleton.rb'
class NewDeviceHandler < com.serotonin.bacnet4j.event.DefaultDeviceEventListener
  # A remote device sends this message in response to broadcast
  # @Override
  def iAmReceived(remote_device)
    name = remote_device.getName
    if name =~ /Yaskawa Node/
      return
    end
    puts "received #{name} #{remote_device.getInstanceNumber}"
    begin
      KnownDevice.discovered(remote_device)
    rescue Exception => e
      LoggerSingleton.logger.error "\n\nerror processing iamrecieved for device #{remote_device.getInstanceNumber}: #{e.to_s}"
    end
  end  
end