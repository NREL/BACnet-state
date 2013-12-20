class OidDiscoverer 
  include java.lang.Runnable
  def initialize(local_device, filters, svc, databus_sender = false)
    @local_device = local_device
    @filters = filters
    @sched_svc = svc
    @sender = databus_sender
  end

  # schedule fresh lookup of Oids for all known devices 
  # distribute start time randomly over an hour
  def run
    new_devices = KnownDevice.where(:refresh_oids_heartbeat => nil).entries
    stale_devices = KnownDevice.where(:refresh_oids_heartbeat.lt => (Time.now - 1.day)).entries
    LoggerSingleton.logger.info "kicking oid discovery.  new device count = #{new_devices.count} and stale device count = #{stale_devices.count}"
    new_devices.each do |kd|
      if kd.complete?
        delay = rand(60)
        LoggerSingleton.logger.info "scheduling oid lookup for device #{kd.instance_number} with delay of #{delay}"
        @sched_svc.schedule(DeviceOidLookup.new(kd, @local_device, @filters, @sender), delay, TimeUnit::SECONDS)
      end
    end
    stale_devices.each do |kd|
      if kd.complete?
        delay = rand(60)
        LoggerSingleton.logger.info "scheduling oid lookup for device #{kd.instance_number} with delay of #{delay}"
        @sched_svc.schedule(DeviceOidLookup.new(kd, @local_device, @filters, @sender), delay, TimeUnit::SECONDS)
      end
    end
  end

end