# Copyright (C) 2013, Alliance for Sustainable Energy
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
########################################################################

class Poll
  include java.lang.Runnable

  attr_reader :poll_delay, :poll_rate

  def initialize(remote_device, local_device, writers, recorder_svc, cached_oids)
    @remote_device = remote_device
    @local_device = local_device
    @writers = writers
    @recorder_svc = recorder_svc
    @cached_oids = cached_oids 
    @refs = create_oid_refs
    # we won't have concurrent runs of this task so we don't need to make this atomic
    @run_count = 0 
    @poll_rate = nil
    @poll_delay = nil
    set_poll_rate_and_delay
  end

  def run 
    begin
      send_request
    rescue Exception=>e
    # this is probably not a correct check.. the java class probably includes prefix...
      if(e.kind_of? BACnetTimeoutException) 
        LoggerSingleton.logger.error "Device timeout for #{@remote_device.instance_number}"
      else
        LoggerSingleton.logger.error "Exception sending/receiving. device= #{@remote_device.instance_number}"
      end
    end
    @run_count = @run_count + 1
  end

  def send_request
    # refs = new PropertyReferences
    if cached_oids.count == 0
      LoggerSingleton.logger.info "no oids to scan to device #{@remote_device.instance_number}"
      return
    end
    
    begin
      start = DateTime.now
      pvs = @local_device.readProperties(@remote_device, @refs)
    # this prob isn't correct type checking on the java exception class
    rescue BACnetException => e
      pvs = read_prop_vals_in_batches
    end
    prop_refs = pvs.iterator
    cur_time = DateTime.now
    #     List<BACnetData> data = new ArrayList<BACnetData>();
    while prop_refs.hasNext 
      # think this pushes onto data object
      data.add(build_data_point(prop_refs.next, pvs, cur_time))
    end
    # fix for jruby
    recorderSvc.execute(new RecordTask(data, writers))
  end

  def read_prop_vals_in_batches 
    lprs = @refs.getPropertiesPartitioned(10)
    lprs.each do |prs|
      LoggerSingleton.logger.info "batch property read for #{@remote_device.instance_number}"
      lpvs = @local_device.readProperties(rd, prs)
      lpvs.each do |opr|
        # todo init pvs
        pvs.add(opr.getObjectIdentifier, opr.getPropertyIdentifier, opr.getPropertyArrayIndex, lpvs.getNoErrorCheck(opr))
      end
    end
    return pvs
  end

# TODO this should create timeseries datum instead fo BACnetData instance...
  def build_data_point(prop_ref, prop_vals, timestamp)
    # TODO may need to cast timestamp.  need full path for data class
    d = new BACnetData(prop_ref.getObjectIdentifier(), try_get_value(prop_ref.getObjectIdentifier(),
    prop_vals, PropertyIdentifier.presentValue), rd.getInstanceNumber(), timestamp);
  end

  def try_get_value (o_id, prop_vals, prop_id)
    begin
      return prop_vals.get(o_id, prop_id)
    # todo use full java class
    rescue PropertyValueException => e
      LoggerSingleton.logger.error "could not retrieve prop #{prop_id} for oid #{o_id}"
      return nil
    end
  end

  def create_oid_refs
    # todo correct path to java class
    refs = PropertyReferences.new
    @cached_oids.each do |oid|
      # todo add tests around these intervals
      #poll_interval_seconds is always divisible by poll_rate (which is a gcd)
      freq = oid.poll_interval_seconds / @poll_rate
      # todo randomize and track the modulus.   This is to distribute less frequently polled sensors in time.  
      # alternatively base this off the poll heartbeat for greater accuracy
      if @run_count % freq == 0 
        refs.add(oid.get_object_identifier, PropertyIdentifier.presentValue)
      end
    end
    return refs
  end
  
  def set_poll_rate_and_delay
    # first, determine poll schedule rate by calculating gcd of all oid polling rates for this device
    intervals = @cached_oids.map{ |oid| oid.poll_interval_seconds }
    start = intervals.pop
    @poll_rate = intervals.inject(start) do |gcd, i|
      i.gcd(gcd) # gcd of current value and previous calculated gcd
    end
    # TODO trigger error for poll_rate below a threshold - say 60
    # poll delay is a random int between 0 and @poll_rate
    @poll_delay = rand(@poll_rate)
  end

end