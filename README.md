Stateful BACnet Scraper
===============

This application works with NREL's [BACnet](https://github.com/NREL/BACnet) library to provide stateful and modular control of 
- Device discovery
- Device OID lookup
- Device polling/data scraping

Discovered devices and oids are persisted to a Mongo database, decoupling discovery from the polling process.

Project funded by NREL's Commercial Building LDRD Project for Building Agent.

-------------------------------

Installation
---------

- JRuby must be installed.  We run the application using JRuby 1.7.4 and cannot confirm compatibility with other versions of JRuby.
- Mongo must be installed and running.
- Clone this repo and run `bundle install`.
- Clone and build NREL's [BACnet Scraper](https://github.com/NREL/bacnet). The BACnet library should be installed at the same level as BACnet-state:
````````sh
/my-project/bacnet
/my-project/bacnet-state
````````

- Add your connection details to config/mongoid.yml.
- Optionally adjust settings in the config/filter.json and config/logging.properties files.

Execution
--------------

The following sample scripts are provided:

- discover_devices.rb runs only device discovery and updates the known_devices collection in Mongo.
`jruby discover_devices.rb -m 0 -M 40000 -databus false -dev en1`
- discover_oids.rb runs oid discovery for all complete known_devices and updates the oids collection.  The filter is also applied to set polling interval for all oids.
`jruby discover_oids.rb -databus false -dev en1`
- poll.rb initializes polling of all complete known_devices at intervals determined by the oids collection.  Note that both device and oid discovery must run before polling can begin.  
`jruby discover_oids.rb -databus false -dev en1`
- run.rb is intended as a complete solution for up to date polling and discovery on a BACnet network.  The script does the following:
  - Immediately schedules polling for all known_devices.
  - Schedules device discovery to run every midnight.
  - Schedules oid discovery and refresh to run every 10 minutes for max of 20 devices each iteration.
  - Schedules detection and polling kick off for newly discovered devices to run every 30 minutes.
`jruby run.rb -databus false -dev en1 -m 0 -M 40000`

Options
---------------

The BACnet-state application exposes the same options as NREL's [BACnet Scraper](https://github.com/NREL/bacnet). Details available with that project.   Note that you must either set the databus option to false or provide databus credentials.  The -dev option is required.

Caveats
---------------
- While our scripts use small threadpools, the code is fundamentally not threadsafe.  Core BACnet functionality is provided by the [BACnet4j](http://sourceforge.net/projects/bacnet4j/) (included with NREL's BACnet scraper).  All requests on the BACnet network must be made via a single instance of the LocalDevice, which is bound to a network device.  This object is not threadsafe.  In our experience, increasing multithreading results in bogus "Device Timeout" messages, but no data integrity issues.


