require 'config/initialize.rb'

# Filter.destroy_all
 # device_ids to exclude from polling
[3,4,7,8,9,10,11,12,13,14,15].each do |i|
  Filter.create(:device_id => i, :priority => 500, :interval => -1)
end

Filter.create(:device_name => "Yaskawa", :priority => 300, :interval => -1 )

#object names to exclude from polling. remember all are applied as Regex
['ALARM','Alarm'].each do |n|
  Filter.create(:object_name => n, :priority => 200, :interval => -1)
end

#object types to exclude from polling. remember all are applied as Regex
["Schedule", "Calendar", "Command", "Device", "EventEnrollment",  "File",  "Group",  "NotificationClass", "Program",  "Averaging", "TrendLog",  "LifeSafetyPoint", "LifeSafetyZone", "Accumulator",  "PulseConverter", "EventLog", "TrendLogMultiple", "LoadControl", "StructuredView",  "AccessDoor",  "VendorSpecific*", "Loop"].each do |n|
  Filter.create(:object_type => n, :priority => 200, :interval => -1)
end

# object types for 60 s polling
["AnalogInput", "BinaryInput", "MultistateInput", "AnalogOutput","BinaryOutput","MultistateOutput"].each do |n|
  Filter.create(:object_type => n, :priority => 100, :interval => 60)
end

# object types for 300 s polling
["AnalogValue", "BinaryValue", "MultistateValue"].each do |n|
  Filter.create(:object_type => n, :priority => 100, :interval => 300)
end

# Everything else: 
Filter.create(:priority => 0, :interval => 7200)

KnownDevice.all.each do |kd|
# kd = KnownDevice.where(:instance_number => 100).first
  kd.apply_oid_filters
end

# db.oids.count()
# 142670
# 142670
# > db.oids.find({poll_interval_seconds: 60}).count()
# 21208
# 17549
# > db.oids.find({poll_interval_seconds: 300}).count()
# 37636
# 31158
# > db.oids.find({poll_interval_seconds: -1}).count()
# 29336
# 88275
# db.oids.find({poll_interval_seconds: 7200}).count()
# 54490
# 0
# db.oids.find({poll_interval_seconds: 7200, object_type_display: /VendorSpecific/}).count()
# 54490






