require 'yaml'

class KnownDevice 
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :instance_number, type: Integer
  field :discovered_heartbeat, type: DateTime
  field :poll_heartbeat, type: DateTime
  field :port, type: Integer
  field :ip_base64, type: String #byte array ?!
  field :network_number, type: Integer
  field :network_address, type: String
  field :max_apdu_length_accepted, type: Integer
  field :segmentation_value, type: Integer 
  field :vendor_id, type: Integer

  # loaded from getExtendedDeviceInformation
  field :name, type: String
  field :protocol_version, type: Integer
  field :protocol_revision, type: Integer

  index({ :instance_number => 1 }, :unique => true)

  @remote_device = nil

  has_many :oids, :dependent => :destroy

  @@local_device = nil

  def self.set_local_device local_device
    @@local_device = local_device
  end

  # create or update Mongo 
  def self.discovered rd
    # look up additional properties
    # assumes that @@local_device has been set.
    @@local_device.getExtendedDeviceInformation rd
    kd = KnownDevice.where(:instance_number => rd.getInstanceNumber).first
    # TODO if the device is already known, do we want to look for any changes?
    if kd.nil?
      kd = KnownDevice.new(:instance_number => rd.getInstanceNumber)
      kd.set_fields rd
    end 
    kd.discovered_heartbeat = Time.now
    kd.save
  end

  def discover_oids local_device
    p = gov.nrel.bacnet.consumer.PropertyLoader.new(local_device)
    oids = p.getOids(self.get_remote_device)
    oids.each do |oid|
      Oid.discover(self, oid)
    end
  end

  # init the remote device if necessary
  def get_remote_device
    if @remote_device.nil?
      init_remote_device
    end
    @remote_device
  end

  # called by static discover method if mongo doesn't already know this device
  def set_fields rd
    require 'base64'
    # assigning these props without "self." prefix doesn't work
    address = rd.getAddress
    if address.present?
      self.port = address.getPort 
      self.ip_base64 = Base64.encode64(String.from_java_bytes(address.getIpBytes))
    end
    network = rd.getNetwork 
    if network.present?
      self.network_number = network.getNetworkNumber
      self.network_address = network.getNetworkAddressDottedString
    end
    self.max_apdu_length_accepted = rd.getMaxAPDULengthAccepted
    self.vendor_id = rd.getVendorId
    self.segmentation_value = rd.getSegmentationSupported.intValue
    self.name = rd.getName 
    self.protocol_version = rd.getProtocolVersion.intValue
    self.protocol_revision = rd.getProtocolRevision.intValue
  end

  def poll_oids local_device, writers
    
  end

private
  # initialize remote device and related java objects
  def init_remote_device 
    require 'base64'
    LoggerSingleton.logger.debug("initializing remote device with id #{instance_number}")
    ip = Base64.decode64(ip_base64).to_java_bytes
    address = com.serotonin.bacnet4j.type.constructed.Address.new(ip, port)
    network = (network_number.present?) ? com.serotonin.bacnet4j.Network.new(network_number, network_address) : nil
    @remote_device = com.serotonin.bacnet4j.RemoteDevice.new(instance_number, address, network)
    @remote_device.setMaxAPDULengthAccepted(max_apdu_length_accepted)
    @remote_device.setVendorId(vendor_id)
    seg = com.serotonin.bacnet4j.type.enumerated.Segmentation.new(segmentation_value)
    @remote_device.setSegmentationSupported(seg)
    @remote_device.setName(name)
    @remote_device.setProtocolVersion(com.serotonin.bacnet4j.type.primitive.UnsignedInteger.new(protocol_version))
    @remote_device.setProtocolRevision(com.serotonin.bacnet4j.type.primitive.UnsignedInteger.new(protocol_revision))
  end

end
