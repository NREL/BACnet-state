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
      if @device.complete?
        # puts "starting to process #{@device.instance_number}"
        start = Time.now.to_i
        @device.discover_oids @local_device
        @device.apply_oid_filters @filters
        if @databus_sender.present?
          # TODO enable this once we test with one device.  may post a new databus stream
          @device.register_oids_with_databus(@databus_sender)
        end
        LoggerSingleton.logger.info "#{DateTime.now} finished processing #{@device.instance_number} in #{Time.now.to_i - start} milliseconds"
      else
        LoggerSingleton.logger.info "#{DateTime.now} faking oid lookup for incomplete known device #{@device.instance_number}"
        @device.refresh_oids_heartbeat = DateTime.now
        @device.save
      end
    rescue Exception => e 
      LoggerSingleton.logger.error "#{DateTime.now} oid scan for device #{@device.instance_number} failed with error #{e.to_s}"
    end
  end
end