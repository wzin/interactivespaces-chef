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

require "chef/monkey_patches/fileutils"
require "chef/mixin/command"
require "chef/mixin/shell_out"
include Chef::Mixin::ShellOut

def whyrun_supported?
  true
end

use_inline_resources

action :deploy do
  if @current_resource.exists
    Chef::Log.debug "Interactivespces Master #{@new_resource.name} already exists - nothing to do"
  else
    converge_by("Deploy #{@new_resource.name}") do
      action_deploy
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::InteractivespacesMaster.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  @current_resource.version(@new_resource.version)
  @current_resource.keep_releases(@new_resource.keep_releases)
  @current_resource.symlinks(@new_resource.symlinks)
  @current_resource.user(@new_resource.user)
  @current_resource.group(@new_resource.group)
  @current_resource.tmp_dir(@new_resource.tmp_dir)
  @current_resource.rollback_on_error(@new_resource.rollback_on_error)
  @current_resource.restart_command(@new_resource.restart_command)
  @current_resource.restart_after_deploy(@new_resource.restart_after_deploy)
  @current_resource.rollback_on_error(@new_resource.rollback_on_error)

  @release_path = @new_resource.deploy_to + "/releases/#{@new_resource.version}"
  @releases_path = @new_resource.deploy_to + "/releases"
  @shared_path = @new_resource.shared_path
  save_release_state

  if current_release?(@release_path)
    Chef::Log.info "No need to deploy - #{@release_path} is good"
  else
    action_deploy
  end
end

private

def action_deploy
  if deployed?(@release_path)
    if current_release?(@release_path)
      Chef::Log.debug("#{@new_resource} is in the latest version")
    else
      rollback_to @release_path
    end
  else
    Chef::Log.info("#{@new_resource} is not in the latest version - deploying")
    with_rollback_on_error do
      deploy
    end
  end
end

private

def deploy
  if deployed?(@release_path)
    Chef::Log.info "#{@new_resource} already deployed to #{@new_resource.deploy_to}"
  else
    verify_directories_exist
    update_files
    enforce_ownership
    symlink
    if @new_resource.restart_after_deploy
      restart
    else
      Chef::Log.info "not restarting #{@new_resource} due to restart_after_deploy=false"
    end
    Chef::Log.info "#{@new_resource} deployed to #{@new_resource.deploy_to}"
  end
end

def update_files
  Chef::Log.debug "Full @new_resource: #{@new_resource.inspect}"
  Chef::Log.debug "Full @current_resource: #{@current_resource.inspect}"

  verify_directories_exist
  create_dir_unless_exists @new_resource.tmp_dir
  fetch_master_jar
  render_izpack
  execute_jar_with_izpack
  move_image_to_release
end

def execute_jar_with_izpack
  command = "/usr/bin/env java -jar #{@new_resource.tmp_dir}/master.jar #{@new_resource.tmp_dir}/master_izpack.xml ;"
  Chef::Log.info "Installing #{@new_resource} with #{command}"
  shell_out(command)
end

def move_image_to_release
  Chef::Log.info "Moving #{@new_resource.tmp_dir}/image to #{@release_path}"
  FileUtils.mv "#{@new_resource.tmp_dir}/image", "#{@release_path}"
end

def render_izpack
  r = Chef::Resource::Template.new("#{@new_resource.tmp_dir}/master_izpack.xml", run_context)
  r.path       "#{@new_resource.tmp_dir}/master_izpack.xml"
  r.source     'master_izpack.xml.erb'
  r.cookbook   'interactivespaces'
  r.owner      @new_resource.user
  r.group      @new_resource.group
  r.mode       00644
  r.run_action :create
end

def render_config_files
  Chef::Log.info "Rendering initial config files"

  create_dir_unless_exists("#{@shared_path}/config/interactivespaces")

  ["container.conf", "interactivespaces/interactivespaces.conf", "interactivespaces/master.conf"].each do |f|
    Chef::Log.info "#{@shared_path}/config/#{f}"
    r = Chef::Resource::Template.new("#{@shared_path}/config/#{f}", run_context)
    r.path       "#{@shared_path}/config/#{f}"
    r.source     "master/#{f}.erb"
    r.cookbook   'interactivespaces'
    r.owner      @new_resource.user
    r.group      @new_resource.group
    r.mode       00644
    r.run_action :create
  end
end

def fetch_master_jar
  command = "wget --no-clobber --tries=3 --timeout=10 --waitretry=1 --read-timeout=20 http://galaxy.endpoint.com/interactivespaces/#{@new_resource.version}/master.jar -O #{@new_resource.tmp_dir}/master.jar"
  Chef::Log.info "Fetching master.jar with #{command}"
  shell_out(command)
end

def verify_directories_exist
  create_dir_unless_exists(@new_resource.deploy_to)
  create_dir_unless_exists(@new_resource.shared_path)
  create_dir_unless_exists(@releases_path)
end

def create_dir_unless_exists(dir)
  if ::File.directory?(dir)
    Chef::Log.info "#{@new_resource} not creating #{dir} because it already exists"
    return false
  end
  converge_by("create new directory #{dir}") do
    begin
      FileUtils.mkdir_p(dir)
      Chef::Log.info "#{@new_resource} created directory #{dir}"
      if @new_resource.user
        FileUtils.chown(@new_resource.user, nil, dir)
        Chef::Log.info("#{@new_resource} set user to #{@new_resource.user} for #{dir}")
      end
      if @new_resource.group
        FileUtils.chown(nil, @new_resource.group, dir)
        Chef::Log.info("#{@new_resource} set group to #{@new_resource.group} for #{dir}")
      end
    rescue => e
      raise Chef::Exceptions::FileNotFound.new("Cannot create directory #{dir}: #{e.message}")
    end
  end
end

def with_rollback_on_error
  yield
rescue ::Exception => e
  if @new_resource.rollback_on_error
    Chef::Log.warn "Error on deploying #{@release_path}: #{e.message}"
    failed_release = @release_path

    if previous_release_path
      @release_path = previous_release_path
      rollback
    end
    converge_by("remove failed deploy #{failed_release}") do
      Chef::Log.info "Removing failed deploy #{failed_release}"
      FileUtils.rm_rf failed_release
    end
    release_deleted(failed_release)
  end

  raise
end

def save_release_state
  if ::File.exists?(@new_resource.current_path)
    release = ::File.readlink(@new_resource.current_path)
    @previous_release_path = release if ::File.exists?(release)
  end
end

def deployed?(release)
  all_releases.include?(release)
end

def current_release?(release)
  @previous_release_path == release
end

def all_releases
  Dir.glob(@new_resource.deploy_to + "/releases/*").sort
end

def rollback
  Chef::Log.info "#{@new_resource} rolling back to previous release #{@release_path}"
  symlink
  Chef::Log.info "#{@new_resource} restarting with previous release"
  restart
end

def symlink
  link_shared_dirs_to_current_release
  link_current_release_to_production
  render_config_files
  Chef::Log.info "#{@new_resource} updated symlinks"
end

def restart
  if restart_cmd = @new_resource.restart_command
    converge_by("restart app using command #{@new_resource.restart_command}") do
      Chef::Log.info("#{@new_resource} restarting app")
      shell_out(@new_resource.restart_command, :user => @new_resource.user, :group => @new_resource.group)
    end
  end
end

def link_current_release_to_production
  converge_by(["remove existing link at #{@new_resource.current_path}",
              "link release #{@release_path} into production at #{@new_resource.current_path}"]) do
    FileUtils.rm_f(@new_resource.current_path)
    begin
      FileUtils.ln_sf(@release_path, @new_resource.current_path)
    rescue => e
      raise Chef::Exceptions::FileNotFound.new("Cannot symlink current release to production: #{e.message}")
    end
    Chef::Log.info "#{@new_resource} linked release #{@release_path} into production at #{@new_resource.current_path}"
  end
  enforce_ownership
end

def link_shared_dirs_to_current_release
  links_info = @new_resource.symlinks.join(", ")
  converge_by("make symlinks: #{links_info}") do
    @new_resource.symlinks.each do |symlink|
      begin
        create_dir_unless_exists("#{@new_resource.shared_path}/#{symlink}")
        FileUtils.rm_rf("#{@release_path}/#{symlink}")
        FileUtils.ln_sf(@new_resource.shared_path + "/#{symlink}", @release_path + "/#{symlink}")
      rescue => e
        raise Chef::Exceptions::FileNotFound.new("Cannot symlink #{@new_resource.shared_path}/#{symlink} to #{@release_path}/#{symlink} - #{e.message}")
      end
    end
    Chef::Log.info "#{@new_resource} made symlinks"
  end
end

def enforce_ownership
  converge_by("force ownership of #{@new_resource.deploy_to} to #{@new_resource.group}:#{@new_resource.user}") do
    FileUtils.chown_R(@new_resource.user, @new_resource.group, @new_resource.deploy_to)
    Chef::Log.info("#{@new_resource} set user to #{@new_resource.user}") if @new_resource.user
    Chef::Log.info("#{@new_resource} set group to #{@new_resource.group}") if @new_resource.group
  end
end


def rollback_to(target_release_path)
  @release_path = target_release_path

  rp_index = all_releases.index(@release_path)
  releases_to_nuke = all_releases[(rp_index + 1)..-1]

  rollback

  releases_to_nuke.each do |i|
    converge_by("roll back by removing release #{i}") do
      Chef::Log.info "#{@new_resource} removing release: #{i}"
      FileUtils.rm_rf i
    end
    release_deleted(i)
  end
end

def release_deleted(release_path)
  #this is for whyrun
end

def rollback
  Chef::Log.info "#{@new_resource} rolling back to previous release #{@release_path}"
  symlink
  Chef::Log.info "#{@new_resource} restarting with previous release"
  restart
end
