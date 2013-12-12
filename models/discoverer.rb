# explicit java_import required?
java_import 'java.util.concurrent.Executors'
java_import 'java.util.concurrent.ScheduledExecutorService'
java_import 'java.util.concurrent.ScheduledFuture'
java_import 'java.util.concurrent.TimeUnit'


class Discoverer 

  def initialize(min_id, max_id, local_device)
    @min = min_id
    @max = max_id
    @local_device = local_device
  end

  # schedule one complete scan of devices from @min to @max.  
  # by scheduling staggered whois broadcasts over subintervals.
  def schedule_broadcast(step = 100, interval_in_secs = 1)
    broadcaster = Broadcaster.new(@min, @max, @local_device, step, interval_in_secs)
    exec = Executors.newScheduledThreadPool(1)
    exec.scheduleAtFixedRate(broadcaster, 0, 1, TimeUnit::SECONDS)
  end

end
