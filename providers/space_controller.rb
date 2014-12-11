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

action :create do
  if @current_resource.exists
    Chef::Log.debug "Controller #{@new_resource.name} already exists - nothing to do"
  else
    converge_by("Create #{@new_resource.name}/#{@new_resource.hostid}") do
      create_controller
    end
  end
end


def load_current_resource
  @current_resource = Chef::Resource::InteractivespacesSpaceController.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.hostid(@new_resource.hostid)
  @current_resource.description(@new_resource.description)

  if controller_exists?
    @current_resource.exists = true
  end
end

private

def create_controller
    cmdstr="python /home/galadmin/src/interactivespaces-python-api/scripts/manage_controller.py \
              --config=/home/galadmin/etc/ispaces-client.conf \
              --action=create \
              --name=#{@new_resource.name} \
              --hostid=#{@new_resource.hostid} \
              --description='#{@new_resource.description}' "
    Chef::Log.debug "Running controller creation command #{cmdstr}"
    cmd = Mixlib::ShellOut.new(cmdstr)
    cmd.run_command
    Chef::Log.debug "CMD stdout: #{cmd.stdout}"
    if cmd.stdout.strip == "True"
      Chef::Log.debug "Created controller: #{cmd.stdout}"
      new_resource.updated_by_last_action(true)
    else
      Chef::Log.debug "Could not create controller: #{cmd.stdout}"
    end
end

private

def controller_exists?
  cmdstr="python /home/galadmin/src/interactivespaces-python-api/scripts/manage_controller.py --config=/home/galadmin/etc/ispaces-client.conf --action=exists --name=#{new_resource.name} --hostid=#{new_resource.hostid}"
  cmd = Mixlib::ShellOut.new(cmdstr)
  cmd.environment['HOME'] = ENV.fetch('HOME', '/home/galadmin/')
  cmd.run_command
  if cmd.stdout.strip == 'True'
    return true
  else
    return false
  end
end
