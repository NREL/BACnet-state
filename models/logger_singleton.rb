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

require 'logger'
class LoggerSingleton
  @@logger = nil
  
  def self.logger
    if @@logger.nil?
      @@logger = Logger.new("logs/ruby_log.log")
      logdev = @@logger.instance_variable_get :@logdev
      logdev.dev.autoclose = false
    end
    @@logger
  end
  private 
  def initialize
  end
end