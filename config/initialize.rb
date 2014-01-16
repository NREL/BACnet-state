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

require 'java'
java_library = "../BACnet/build/bacnet/lib/"
Dir["#{java_library}\*.jar"].each { |jar| require jar }
def gov
  Java::Gov
end

require 'mongoid'
Mongoid.load!("config/mongoid.yml", :development)
Dir["models/\*.rb"].each { |rb| require rb }

java_import 'java.util.concurrent.TimeUnit'
java_import 'com.serotonin.bacnet4j.service.unconfirmed.WhoIsRequest'
java_import 'gov.nrel.bacnet.consumer.BACnet'
java_import 'gov.nrel.bacnet.consumer.PollDeviceTask'

