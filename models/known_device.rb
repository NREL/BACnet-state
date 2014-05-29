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

require 'yaml'

class KnownDevice 
  include Mongoid::Document
  include Mongoid::Timestamps
 
  field :instance_number, type: Integer
  field :discovered_heartbeat, type: DateTime

  # refresh_heartbeat and refresh_oids_heartbeat are updated on *attempted* refesh rather than success.  this is to prevent constant ping of devices that time out up often send iAm messages
  field :refresh_heartbeat, type: DateTime #last time data for this device was updated (includes getExtendedDeviceInformation network call)
  field :refresh_oids_heartbeat, type: DateTime #last time oids list was retrieved for device

  # this does not record success but should tell us whether polling is running.
  field :attempted_poll_heartbeat, type: DateTime
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
    kd = KnownDevice.find_or_initialize_by(:instance_number => rd.getInstanceNumber)

    LoggerSingleton.logger.info "Discovered device : #{rd.getInstanceNumber} #{kd.refresh_heartbeat}"

    kd.discovered_heartbeat = Time.now
    kd.upsert

    # run the set fields to refresh mongo once a week
    if kd.refresh_heartbeat.nil? or kd.refresh_heartbeat < (Time.now - 1.day)
      kd.set_fields rd
    end
  end

  def discover_oids local_device
    # record every attempt to refresh oids
    self.refresh_oids_heartbeat = Time.now
    self.update

    id = self.get_remote_device.getObjectIdentifier
    p = gov.nrel.bacnet.consumer.PropertyLoader.new(local_device)
    oids = p.getOids(self.get_remote_device)
    LoggerSingleton.logger.info "#{DateTime.now} Discovered #{oids.size} oids on #{self.get_remote_device.getInstanceNumber}"

    begin
      extra_props = p.getProperties(self.get_remote_device, oids)
      LoggerSingleton.logger.info "#{DateTime.now} Discovered #{extra_props.size} properties on #{self.get_remote_device.getInstanceNumber}"
    rescue Exception => e
      LoggerSingleton.logger.error "#{DateTime.now} exception while discovering properties on  #{self.get_remote_device.getInstanceNumber}"
      raise e
    end
    oids.each do |oid|
      begin
        Oid.discover(self, oid, extra_props)
      rescue Exception => e 
        LoggerSingleton.logger.error "#{DateTime.now} oid discovery for device #{@device.instance_number} failed with error #{e.to_s} oid #{oid.to_s}. Continuing with next oid"
      end
    end
  end

  # register databus stream for each oid with a polling interval > -1 (aka any oid we poll)
  def register_oids_with_databus sender
    pollable_oids = oids.where(:poll_interval_seconds.gt => -1).entries

    pollable_oids.each do |oid|
      sender.postNewStream(oid.get_stream_for_writing, get_device_for_writing, "bacnet", "0")
    end
  end

  # init the remote device if necessary
  def get_remote_device
    if @remote_device.nil?
      init_remote_device
    end
    @remote_device
  end

  # we want to be able to save devices that respond, even if they later time out on the getextendeddevice request 
  # this allows us to track when we last refreshed them.  for oid lookup and polling purposes, we will ignore devices that are not complete
  def complete?
    # protocol version is set by getExtendedDevice request and should be good indicator of whether that ran
    !protocol_version.nil? || !name.nil?
  end

  def set_fields rd
    require 'base64'
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
    self.refresh_heartbeat = Time.now
    self.update

    # These are set from extended device info which may time out (so we update refresh and save first)
    # assumes @@local_device has been set
    @@local_device.getExtendedDeviceInformation rd
    self.name = rd.getName 
    self.protocol_version = rd.getProtocolVersion.intValue
    self.protocol_revision = rd.getProtocolRevision.intValue
    self.update # make sure just added info is saved to DB too
  end

  def apply_oid_filters 
    oids.each do |oid|
      Filter.all.sort(:priority.desc).each do |f|
        # if you found a match, save and skip to next oid
        if f.match(oid)
          # puts "setting poll interval for oid #{oid.object_name} to #{f.interval} because of match with filter #{f.inspect}"
          oid.poll_interval_seconds = f.interval
          oid.update
          break
        end
      end
      # if there were no matches, we won't change anything for now
    end
  end

  def get_device_for_writing
    dev = gov.nrel.bacnet.consumer.beans.Device.new
    description = name.to_s #may be null
    space_i = description.index " " 
    uscore_i = description.index "_"
    site = (description =~ /^NWTC/) ? "NWTC" : "STM"
    ""
    if description =~ /^(CP|FTU|1ST)/
      bldg = "RSF" 
    elsif description =~ /^Garage/
      bldg = "Garage"
    # elsif description =~ /^STF/
    #   bldg = "STF"
    elsif space_i or (space_i and uscore_i and (space_i < uscore_i))
      tmp = description.split(" ")
      bldg = tmp.shift
      description = tmp.join(" ")
    else
      tmp = description.split("_")
      bldg = tmp.shift
      description = tmp.join(" ")
    end

    device_id = "#{KnownDevice::BACNET_PREFIX}#{instance_number}"

    dev.setDeviceId(device_id);
    dev.setDeviceDescription(description);
    dev.setOwner("NREL")
    dev.setSite(site)
    dev.setBldg(bldg)
    dev.setEndUse("unknown")
    dev.setProtocol("BACNet")
    dev.setAddress(ip_display) if ip_display
    dev
  end

private
  # initialize remote device and related java objects
  def init_remote_device 
    require 'base64'
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
