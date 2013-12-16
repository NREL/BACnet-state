class DeviceOidLookup
  include java.lang.Runnable
  def initialize known_device, local_device
    @device = known_device
    @local_device = local_device
  end
  def run
    begin
      puts "starting to process #{@device.instance_number}"
      start = Time.now.to_i
      @device.discover_oids @local_device
      puts "finished processing #{@device.instance_number} in #{Time.now.to_i - start} milliseconds"
    rescue Exception => e 
      LoggerSingleton.logger.error "oid scan for device #{@device.instance_number} failed with error #{e.to_s}"
    end
  end
end