class NewDevicePollScheduler 
  include java.lang.Runnable

  def initialize local_device, our_exec, writers
    @local_device = local_device
    @exec = our_exec
    @writers = writers
  end

  def run
    begin
      # Look for any devices that we have never attempted to poll (newly discovered) and schedule to poll 
      new_devices = KnownDevice.where(:attempted_poll_heartbeat => nil, :refresh_oids_heartbeat.ne => nil).entries
      new_devices.each do |kd| 
        if kd.complete?
          remote_device = kd.get_remote_device
          polltask = PollDeviceTask.new(remote_device,@local_device,writers)
          oids = kd.oids.where(:poll_interval_seconds.gt => -1).entries
          oids.each do |o| 
            polltask.addInterval(o.get_object_identifier, o.poll_interval_seconds) 
          end
          polltask.setCachedOids(oids.map{|o| o.get_object_identifier})
          delay = polltask.init()
          puts "initializing polling of device #{kd.instance_number} with #{oids.count} pollable oids. interval = #{delay.getInterval} and initial delay = #{delay.getDelay}"
          pollone = SchedulablePoll.new(polltask, @exec, kd)
          @exec.getScheduledSvc.scheduleAtFixedRate(pollone, delay.getDelay, delay.getInterval, TimeUnit::SECONDS)
        end
      end
    rescue Exception => e
      LoggerSingleton.logger.error "\n\nerror scheduling new poll schedulers: #{e.to_s}: #{e.backtrace.join("\n")}"
    end
  end
end