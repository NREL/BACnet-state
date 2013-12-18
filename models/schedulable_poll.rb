class SchedulablePoll 
  include java.lang.Runnable

  def initialize polltask, exec
    @polltask = polltask
    @exec = exec
  end

  def run
    begin
      # schedule on fixed threadpool with queue management
      # need to update mongo on successful completion
      # may also want to notify mongo of failed execution
      @exec.execute(@polltask)
    # rescue from exception so scheduled polling is not terminated
    rescue Exception => e
      LoggerSingleton.logger.error "\n\nerror running polling task: #{e.to_s}: #{e.backtrace.join("\n")}"
    end
  end
end