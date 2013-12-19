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
    KnownDevice.all.each do |kd|
      delay = rand(60)
      LoggerSingleton.logger.info "scheduling oid lookup for device #{kd.instance_number} with delay of #{delay}"
      @sched_svc.schedule(DeviceOidLookup.new(kd, @local_device, @filters, @sender), delay, TimeUnit::SECONDS)
    end
  end

end