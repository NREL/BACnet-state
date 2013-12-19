# require 'java'
# require '../../../src/main/ruby/logger_singleton.rb'
class NewDeviceHandler < com.serotonin.bacnet4j.event.DefaultDeviceEventListener
  # A remote device sends this message in response to broadcast
  # @Override
  def iAmReceived(remote_device)
    name = remote_device.getName
    if name =~ /Yaskawa Node/
      return
    end
    puts "received #{name} #{remote_device.getInstanceNumber}"
    begin
      KnownDevice.discovered(remote_device)
    rescue Exception => e
      LoggerSingleton.logger.error "\n\nerror processing iamrecieved: #{e.to_s}: #{e.backtrace.join("\n")}"
    end
  end  
end