class SchedulablePoll 
  include java.lang.Runnable

  def initialize polltask, exec, known_device
    @polltask = polltask
    @exec = exec
    @known_device = known_device
  end

  def run
    begin
      LoggerSingleton.logger.info "\n\n#{DateTime.now} Starting polling for device #{@known_device.instance_number}"
      # recode that we are about to attempt polling
      @known_device.attempted_poll_heartbeat = Time.now
      @known_device.save
      # schedule on fixed threadpool with queue management
      # need to update mongo on successful completion
      # may also want to notify mongo of failed execution
      @exec.execute(@polltask)
    # rescue from exception so scheduled polling is not terminated
    rescue Exception => e
      LoggerSingleton.logger.error "\n\n#{DateTime.now} error running polling task: #{e.to_s}: #{e.backtrace.join("\n")}"
    end
  end
end