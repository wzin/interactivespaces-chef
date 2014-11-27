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
require 'json'

def whyrun_supported?
  true
end

action :create do
  if @current_resource.exists
    Chef::Log.debug "Live activity #{@new_resource.name} already exists - nothing to do"
  else
    converge_by("Create #{@new_resource.name}") do
      create_live_activity
    end
  end
  if @current_resource.metadata_up_to_date
    Chef::Log.debug "Live activity #{@new_resource.name} already exists - nothing to do"
  else
    converge_by("Update metadata of #{@new_resource.name}") do
      update_live_activity_metadata
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::InteractivespacesLiveActivity.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.activity_name(@new_resource.activity_name)
  @current_resource.controller_name(@new_resource.controller_name)
  @current_resource.description(@new_resource.description)
  @current_resource.metadata(@new_resource.metadata).to_json

  if live_activity_exists?
    @current_resource.exists = true
    if live_activity_metadata_up_to_date?
      @current_resource.metadata_up_to_date = true
    end
  end

end

private

def create_live_activity
  cmdstr = "python /home/galadmin/src/interactivespaces-python-api/scripts/manage_live_activity.py --config=/home/galadmin/etc/ispaces-client.conf --action=create --name='#{new_resource.name}'  --controller-name='#{new_resource.controller_name}' --activity-name='#{new_resource.activity_name}' --description='#{new_resource.description}'"
  Chef::Log.debug "Running live activity create command #{cmdstr}"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.run_command
  if cmd.stdout.strip == "True"
    Chef::Log.debug "Crated live activity: #{cmd.stdout}"
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.debug "Could not create live activity: #{cmd.stdout}"
  end
end

def update_live_activity_metadata
  cmdstr="python /home/galadmin/src/interactivespaces-python-api/scripts/manage_live_activity.py  --config=/home/galadmin/etc/ispaces-client.conf --action=update_metadata --name='#{new_resource.name}'  --controller-name='#{new_resource.controller_name}' --metadata='#{new_resource.metadata.to_json}'"
  Chef::Log.debug "Running live activity metadata update command #{cmdstr}"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.run_command
  if cmd.stdout.strip == "True"
    Chef::Log.debug "Updated metadata for live activity: #{cmd.stdout}"
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.debug "Live activity metadata could not be updated #{cmd.stdout}"
  end
end

private

def live_activity_exists?
  cmdstr = "python /home/galadmin/src/interactivespaces-python-api/scripts/manage_live_activity.py --config=/home/galadmin/etc/ispaces-client.conf --action=exists --name='#{new_resource.name}'  --controller-name='#{new_resource.controller_name}'"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.environment['HOME'] = ENV.fetch('HOME', '/home/galadmin/')
  cmd.run_command
  Chef::Log.debug "Does the live activity_exist? => #{cmd.stdout}"
  if cmd.stdout.strip == 'True'
    return true
  else
    return false
  end
end

def live_activity_metadata_up_to_date?
  cmdstr="python /home/galadmin/src/interactivespaces-python-api/scripts/manage_live_activity.py  --config=/home/galadmin/etc/ispaces-client.conf --action=metadata_up_to_date --name='#{new_resource.name}'  --controller-name='#{new_resource.controller_name}' --metadata='#{new_resource.metadata.to_json}'"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.environment['HOME'] = ENV.fetch('HOME', '/home/galadmin/')
  cmd.run_command
  Chef::Log.debug "Does the live activity_exist? => #{cmd.stdout}"
  if cmd.stdout.strip == 'True'
    return true
  else
    return false
  end
end
