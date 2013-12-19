class DeviceOidLookup
  include java.lang.Runnable
  def initialize known_device, local_device, filters, databus_sender = nil
    @device = known_device
    @local_device = local_device
    @filters = filters
    @databus_sender = databus_sender
  end
  def run
    begin
      # puts "starting to process #{@device.instance_number}"
      start = Time.now.to_i
      @device.discover_oids @local_device
      @device.apply_oid_filters @filters
      if @databus_sender.present?
        # TODO enable this once we test with one device.  may post a new databus stream
        @device.register_oids_with_databus(@databus_sender)
      end
      puts "finished processing #{@device.instance_number} in #{Time.now.to_i - start} milliseconds"
    rescue Exception => e 
      LoggerSingleton.logger.error "oid scan for device #{@device.instance_number} failed with error #{e.to_s}"
    end
  end
end