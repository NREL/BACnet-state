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

# require 'mongoid'
# require 'java'
class Oid
  include Mongoid::Document
  include Mongoid::Timestamps
  field :instance_number, type: Integer
  field :object_type_int, type: Integer
  field :object_type_display, type: String
  field :object_name, type: String
  field :units, type: String
  field :poll_interval_seconds, type: Integer, default: -1 #off by default
  field :discovered_heartbeat, type: DateTime
  field :poll_heartbeat, type: DateTime

  # object instance number is unique within device
  index({ :instance_number => 1, :known_device_id => 1, :object_type_int => 1 }, :unique => true)

  belongs_to :known_device

  @object_identifier = nil

  def self.discover known_device, o, extra_props
    begin
      oid = known_device.oids.where(:object_type_int => o.getObjectType.intValue, :instance_number => o.getInstanceNumber).first || known_device.oids.new
      oid.set_fields(o, extra_props)
      oid.discovered_heartbeat = Time.now
      oid.save!
    rescue Exception => e
      LoggerSingleton.logger.error "#{DateTime.now} error discovering oid #{oid.inspect}.  Error: #{e.to_s}: #{e.backtrace.join("\n")}"
    end
  end

  def set_fields o, extra_props
    type_display = o.getObjectType.toString.gsub(/[ |-]/,"")
    o_name = extra_props.get(gov.nrel.bacnet.consumer.beans.ObjKey.new(o, com.serotonin.bacnet4j.type.enumerated.PropertyIdentifier.objectName))
    o_units = extra_props.get(gov.nrel.bacnet.consumer.beans.ObjKey.new(o, com.serotonin.bacnet4j.type.enumerated.PropertyIdentifier.units))
    self.object_type_int = o.getObjectType.intValue
    self.instance_number = o.getInstanceNumber 
    self.object_type_display = type_display
    self.object_name = o_name 
    self.units = o_units
  end

  def get_object_identifier
    if @object_identifier.nil?
  	 ob_type = com.serotonin.bacnet4j.type.enumerated.ObjectType.new(object_type_int)
  	 @object_identifier = com.serotonin.bacnet4j.type.primitive.ObjectIdentifier.new(ob_type,instance_number)
    end
    @object_identifier
  end

  def get_stream_for_writing
    str = gov.nrel.bacnet.consumer.beans.Stream.new
    str.setTableName(form_databus_table_name)
    str.setStreamDescription(object_name.to_s)
    str.setUnits(units.to_s)
    str.setDevice(known_device.instance_number.to_s)
    str.setStreamType(object_type_display.to_s)
    str.setStreamId(instance_number.to_s)
    return str
  end

  def form_databus_table_name
    "#{KnownDevice::BACNET_PREFIX}#{known_device.instance_number}#{object_type_display}#{instance_number.to_s}"
  end
end