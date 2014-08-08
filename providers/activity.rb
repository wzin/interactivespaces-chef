#
# Author:: Wojciech Ziniewicz (<wojtek@endpoint.com>)
#
# Copyright 2014, End Point
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

def whyrun_supported?
  true
end

action :upload do
  if activity_exists?(new_resource.activity)
      Chef::Log.debug "Activity #{new_resource.activity} exists."
  else
    cmd_string="python /home/galadmin/src/interactivespaces-python-api/scripts/manage_activity.py --action=upload --url=#{url}"
    execute cmd_string do
      Mixlib::ShellOut.new(cmd_string)
      new_resource.updated_by_last_action(true)
      Chef::Log.debug "uploaded activity: #{cmd.stdout}"
    end
  end
end

def activity_exists?(name, version)
  if version:
    version = "--version=#{version}"
  end

  cmdstr="python /home/galadmin/src/interactivespaces-python-api/scripts/manage_activity.py --action=exists --name=#{activity_name} #{version}"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.environment['HOME'] = ENV.fetch('HOME', '/home/galadmin/')
  cmd.run_command
  Chef::Log.debug "rabbitmq_plugin_enabled?: #{cmdstr}"
  Chef::Log.debug "rabbitmq_plugin_enabled?: #{cmd.stdout}"
  cmd.error!
end
