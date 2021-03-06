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
  if @current_resource.exists
    Chef::Log.debug "Activity #{@new_resource} already exists - nothing to do"
  else
    converge_by("Create #{@new_resource}") do
      upload_activity
    end
  end
end


def load_current_resource
  @current_resource = Chef::Resource::InteractivespacesActivity.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.url(@new_resource.url)
  @current_resource.version(@new_resource.version)

  if activity_exists?
    @current_resource.exists = true
  end
end

private

def upload_activity
    cmdstr="python /home/galadmin/src/interactivespaces-python-api/scripts/manage_activity.py --config=/home/galadmin/etc/ispaces-client.conf --action=upload --url=#{new_resource.url}"
    Chef::Log.debug "Running activity upload command #{cmdstr}"
    cmd = Mixlib::ShellOut.new(cmdstr)
    cmd.run_command
    Chef::Log.debug "CMD stdout: #{cmd.stdout}"
    if cmd.stdout.strip == "True"
      Chef::Log.debug "Uploaded activity: #{cmd.stdout}"
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.debug "Could not upload activity: #{cmd.stdout}"
    end
end

private

def activity_exists?
  Chef::Log.debug "Checking to see if activity name '#{new_resource.name} / #{new_resource.version}' exists"
  if new_resource.version
    version = "--version='#{version}'"
  end

  cmdstr="python /home/galadmin/src/interactivespaces-python-api/scripts/manage_activity.py  --config=/home/galadmin/etc/ispaces-client.conf --action=exists --name='#{new_resource.name}' #{version}"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.environment['HOME'] = ENV.fetch('HOME', '/home/galadmin/')
  cmd.run_command
  Chef::Log.debug "Does the activity_exist? => #{cmd.stdout}"
  if cmd.stdout.strip == 'True'
    return true
  else
    return false
  end
end
