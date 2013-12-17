require 'yaml'

class KnownDevice 
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :instance_number, type: Integer
  field :discovered_heartbeat, type: DateTime
  field :poll_heartbeat, type: DateTime
  field :port, type: Integer
  field :ip_base64, type: String #byte array ?!
  field :ip_display, type: String #for visual inspection
  field :network_number, type: Integer
  field :network_address, type: String
  field :max_apdu_length_accepted, type: Integer
  field :segmentation_value, type: Integer 
  field :vendor_id, type: Integer

  # loaded from getExtendedDeviceInformation
  field :name, type: String
  field :protocol_version, type: Integer
  field :protocol_revision, type: Integer

  #random offset for polling, used to stagger network requests
  field :poll_delay, type: Integer, default: 0 

  index({ :instance_number => 1 }, :unique => true)

  has_many :oids, :dependent => :destroy
  BACNET_PREFIX = "bacnet" 

  @@local_device = nil
  @remote_device = nil

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
    extra_props = p.getProperties(self.get_remote_device, oids)
    oids.each do |oid|
      Oid.discover(self, oid, extra_props)
    end
  end

  # register databus stream for each oid with a polling interval > -1 (aka any oid we poll)
  def register_oids_with_databus sender
    pollable_oids = oids.where(:poll_interval_seconds.gt => -1)
    sender.postNewStream(oid.create_stream, get_device_for_writing, "bacnet", 0)
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
      self.ip_display = address.toIpPortString
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

  def apply_oid_filters filters
    oids.each do |oid|
      i = filters.getPollingInterval(get_remote_device, oid.get_object_identifier)
      oid.poll_interval_seconds = i
      oid.save
    end
  end

  def get_device_for_writing
    dev = gov.nrel.bacnet.consumer.beans.Device.new
    description = name
    space_i = description.index " " 
    uscore_i = description.index "_"
    site = (description =~ /^NWTC/) ? "NWTC" : "STM"
    ""
    description = description.to_s #may come through as nil
    if description =~ /^(CP|FTU|1ST)/
      bldg = "RSF" 
    elsif description =~ /^Garage/
      bldg = "Garage"
    elsif space_i and uscore_i and (space_i < uscore_i)
      bldg = description.split(" ").first
    else
      bldg = description.split("_").first
    end

    device_id = self::BACNET_PREFIX+instance_number

    dev.setDeviceId(device_id);
    dev.setDeviceDescription(name);
    dev.setOwner("NREL")
    dev.setSite(site)
    dev.setBldg(bldg)
    dev.setEndUse("unknown")
    dev.setProtocol("BACNet")
    dev.setAddress(ip_display) if ip_display
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
