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

class Filter 
	include Mongoid::Document
	include Mongoid::Timestamps

	field :device_id, type: Integer
	field :device_name, type: String, default: ".*"
	field :object_id, type: Integer
  field :object_type, type: String, default: ".*"
	field :object_name, type: String, default: ".*"
	field :interval, type: Integer, default: -1
	field :priority, type: Integer, default: 0 #filters are applied in descending priority.  First match is what we use.

	index({ :priority => -1 })

	def match oid 
    # match integer ids, but only if set
    id_match = (device_id.nil? or device_id == oid.known_device.instance_number) and (object_id.nil? or object_id == oid.instance_number)
    # text matches
    # if object_name != '.*' and oid.object_name =~ Regexp.new(object_name) 
    #   puts "oid ob name #{oid.object_name} matches #{object_name}"
    # end
    string_match = (oid.known_device.name =~ Regexp.new(device_name) and oid.object_type_display =~ Regexp.new(object_type) and oid.object_name =~ Regexp.new(object_name))
    id_match and string_match
  end

end