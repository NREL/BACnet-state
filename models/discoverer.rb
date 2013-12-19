class Discoverer 
  include java.lang.Runnable
  def initialize(min_id, max_id, local_device, svc, step = 100, delay = 0, interval_in_secs = 1)
    @min = min_id
    @max = max_id
    @local_device = local_device
    @sched_svc = svc
    @step = step
    @interval_in_secs = interval_in_secs
  end

  # schedule one complete scan of devices from @min to @max.  
  # by scheduling staggered whois broadcasts over subintervals.
  def run
    broadcaster = Broadcaster.new(@min, @max, @local_device, @step)
    puts "starting broadcast of range #{@min} to #{@max} in steps of #{@step} at interval of #{@interval_in_secs}"
    @sched_svc.scheduleAtFixedRate(broadcaster, @delay, @interval_in_secs, TimeUnit::SECONDS)
  end

end
