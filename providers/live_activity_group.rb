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
    Chef::Log.debug "Live activity group #{@new_resource.name} already exists - nothing to do"
  else
    converge_by("Create #{@new_resource.name}") do
      create_live_activity_group
    end
  end
  if @current_resource.metadata_up_to_date
    Chef::Log.debug "Live activity group #{@new_resource.name} metadata up to date"
  else
    converge_by("Create #{@new_resource.name}") do
      update_metadata
    end
  end
  if @current_resource.live_activities_up_to_date
    Chef::Log.debug "Live activity group #{@new_resource.name} live activities up to date"
  else
    converge_by("Create #{@new_resource.name}") do
      update_live_activities_list
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::InteractivespacesLiveActivityGroup.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.description(@new_resource.description)
  @current_resource.metadata(@new_resource.metadata).to_json
  @current_resource.live_activities(@new_resource.live_activities).to_json

  if live_activity_group_exists?
    @current_resource.exists = true
  end
  if metadata_up_to_date?
    @current_resource.metadata_up_to_date = true
  end
  if live_activity_list_up_to_date?
    @current_resource.live_activities_up_to_date = true
  end
end

private

def live_activity_group_exists?
  cmdstr = "python /home/galadmin/src/interactivespaces-python-api/scripts/manage_live_activity_group.py --config=/home/galadmin/etc/ispaces-client.conf --action=exists --name='#{new_resource.name}'"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.environment['HOME'] = ENV.fetch('HOME', '/home/galadmin/')
  cmd.run_command
  Chef::Log.debug "Does live_activity_group_exists? => #{cmd.stdout}"
  if cmd.stdout.strip == 'True'
    return true
  else
    return false
  end
end

def create_live_activity_group
  cmdstr = "python /home/galadmin/src/interactivespaces-python-api/scripts/manage_live_activity_group.py --config=/home/galadmin/etc/ispaces-client.conf --action=create --name='#{new_resource.name}' --live-activities='#{new_resource.live_activities.to_json}' --description='#{new_resource.description}'"
  Chef::Log.debug "Running create_live_activity_group #{cmdstr}"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.run_command
  if cmd.stdout.strip == "True"
    Chef::Log.debug "create_live_activity_group: #{cmd.stdout}"
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.debug "Could create_live_activity_group: #{cmd.stdout}"
  end
end

def update_metadata
  cmdstr = "python /home/galadmin/src/interactivespaces-python-api/scripts/manage_live_activity_group.py --config=/home/galadmin/etc/ispaces-client.conf --action=update_metadata --name='#{new_resource.name}' --metadata='#{new_resource.metadata.to_json}'"
  Chef::Log.debug "Running update_metadata #{cmdstr}"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.run_command
  if cmd.stdout.strip == "True"
    Chef::Log.debug "update_metadata: #{cmd.stdout}"
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.debug "Could not update_metadata: #{cmd.stdout}"
  end
end

def metadata_up_to_date?
  cmdstr = "python /home/galadmin/src/interactivespaces-python-api/scripts/manage_live_activity_group.py --config=/home/galadmin/etc/ispaces-client.conf --action=metadata_up_to_date --name='#{new_resource.name}' --metadata='#{new_resource.metadata.to_json}'"  
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.environment['HOME'] = ENV.fetch('HOME', '/home/galadmin/')
  cmd.run_command
  Chef::Log.debug "metadata_up_to_date? => #{cmd.stdout}"
  if cmd.stdout.strip == 'True'
    return true
  else
    return false
  end
end

def update_live_activities_list
  cmdstr = "python /home/galadmin/src/interactivespaces-python-api/scripts/manage_live_activity_group.py --config=/home/galadmin/etc/ispaces-client.conf --action=update_live_activities_list --name='#{new_resource.name}'  --live-activities='#{new_resource.live_activities.to_json}'"
  Chef::Log.debug "Running update_live_activities_liste command #{cmdstr}"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.run_command
  if cmd.stdout.strip == "True"
    Chef::Log.debug "update_live_activities_list: #{cmd.stdout}"
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.debug "Could not update_live_activities_list: #{cmd.stdout}"
  end
end

def live_activity_list_up_to_date?
  cmdstr = "python /home/galadmin/src/interactivespaces-python-api/scripts/manage_live_activity_group.py --config=/home/galadmin/etc/ispaces-client.conf --action=live_activities_up_to_date --name='#{new_resource.name}'  --live-activities='#{new_resource.live_activities.to_json}'"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.environment['HOME'] = ENV.fetch('HOME', '/home/galadmin/')
  cmd.run_command
  Chef::Log.debug "live_activity_list_up_to_date? => #{cmd.stdout}"
  if cmd.stdout.strip == 'True'
    return true
  else
    return false
  end
end


