# require 'mongoid'
# require 'java'
class Oid
  include Mongoid::Document
  include Mongoid::Timestamps
  field :instance_number, type: Integer
  field :object_type_int, type: Integer
  field :object_type_display, type: String
  field :polling_enabled, type: Boolean, default: false
  field :discovered_heartbeat, type: DateTime
  field :poll_heartbeat, type: DateTime

  # object instance number is unique within device
  index({ :instance_number => 1, :known_device_id => 1 }, :unique => true)

  belongs_to :known_device

  def self.discover known_device, o 
    begin
      oid = known_device.oids.where(:object_type_int => o.getObjectType.intValue, :instance_number => o.getInstanceNumber).first
      if oid.present?
        oid.discovered_heartbeat = Time.now
        oid.save
      else
        # TODO any other meta to save?
        oid = known_device.oids.create!(:object_type_int => o.getObjectType.intValue, :instance_number => o.getInstanceNumber, :object_type_display => o.getObjectType.toString, :discovered_heartbeat => Time.now)
      end
    rescue Exception => e
      LoggerSingleton.logger.error "\n\nerror discovering oid #{oid.inspect}.  Error: #{e.to_s}: #{e.backtrace.join("\n")}"
    end
  end

  def get_object_identifier
  	ob_type = com.serotonin.bacnet4j.type.enumerated.ObjectType.new(object_type_int)
  	oid = com.serotonin.bacnet4j.type.primitive.ObjectIdentifier.new(ob_type,oid_id)
  end

end