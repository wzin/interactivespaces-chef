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

actions [:deploy, :rollback]
default_action :deploy

attribute :deploy_to, :kind_of => String, :name_attribute => true, :default => node[:interactivespaces][:controller][:deploy][:deploy_to]
attribute :version, :kind_of => String, :default => node[:interactivespaces][:version]
attribute :keep_releases, :kind_of => Integer, :default => 5
attribute :current_path, :kind_of => String, :default => "#{node[:interactivespaces][:controller][:deploy][:deploy_to]}/current"
attribute :shared_path, :kind_of => String, :default => "#{node[:interactivespaces][:controller][:deploy][:deploy_to]}/shared"
attribute :ssh_user, :kind_of => String, :default => "#{node[:interactivespaces][:controller][:deploy][:ssh_user]}"
attribute :user, :kind_of => String, :default => "#{node[:interactivespaces][:controller][:deploy][:user]}"
attribute :group, :kind_of => String, :default => "#{node[:interactivespaces][:controller][:deploy][:group]}"
attribute :symlinks, :kind_of => Array, :default => node[:interactivespaces][:controller][:deploy][:symlinks]
attribute :restart_command, :kind_of => String, :default => node[:interactivespaces][:controller][:deploy][:restart_cmd]
attribute :restart_after_deploy, :kind_of => [TrueClass, FalseClass], :default => true
attribute :tmp_dir, :kind_of => String, :default => node[:interactivespaces][:controller][:deploy][:tmp_dir]
attribute :rollback_on_error, :kind_of => [TrueClass, FalseClass]
attribute :host_address, :kind_of => String
attribute :remote, :kind_of => [TrueClass, FalseClass], :default => true
attribute :templates_tmp_root, :kind_of => String, :default => node[:interactivespaces][:controller][:deploy][:templates_tmp_root]
attribute :fail_on_error, :kind_of => [TrueClass, FalseClass], :default => node[:interactivespaces][:controller][:deploy][:fail_on_error]

attr_accessor :exists
