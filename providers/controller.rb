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
include Chef::Mixin::ShellOut

def whyrun_supported?
  true
end

use_inline_resources

action :deploy do
  if @current_resource.exists
    #TODO (WZ): make .exists method
    Chef::Log.debug "Interactivespces Controller #{@new_resource.name} already exists - nothing to do"
  else
    converge_by("Deploy #{@new_resource.name}") do
      action_deploy
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::InteractivespacesController.new(@new_resource.name)
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
  @current_resource.host_address(@new_resource.host_address)
  @current_resource.remote(@new_resource.remote)
  @current_resource.fail_on_error(@new_resource.fail_on_error)

  @templates_tmp_root = @new_resource.templates_tmp_root + "/#{@new_resource.host_address}"
  @release_path = @new_resource.deploy_to + "/releases/#{@new_resource.version}"
  @releases_path = @new_resource.deploy_to + "/releases"
  Chef::Log.info("Releases path = #{@releases_path}")
  @shared_path = @new_resource.shared_path
  save_release_state

  if current_release?("#{@new_resource.deploy_to}/releases/#{@new_resource.version}")
    Chef::Log.info "No need to deploy - #{@release_path} is good"
  else
    action_deploy
  end
end


def action_deploy
  if host_is_up?(@new_resource.host_address)
    if deployed?(@release_path)
      Chef::Log.info("#{@new_resource} is deployed in #{@release_path}")
      if current_release?(@release_path)
        Chef::Log.info("#{@new_resource} is in the latest version under #{@release_path}")
      else
        rollback_to @release_path
      end
    else
      Chef::Log.info("#{@new_resource} is not in the latest version - deploying")
      with_rollback_on_error do
        deploy
      end
    end
  else
    log "Host #{@new_resource.host_address} is not up - not deploying controller on it"
  end
end


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
  fetch_controller_jar
  render_izpack
  execute_jar_with_izpack
  rsync_image_to_release
end

def execute_jar_with_izpack
  command = "/usr/bin/env java -jar #{@new_resource.tmp_dir}/controller.jar #{@templates_tmp_root}/controller_izpack.xml ;"
  Chef::Log.info "Installing #{@new_resource} with #{command}"
  cmd = shell_out(command)
  Chef::Log.info "Installation exit status: #{cmd.exitstatus}"
end

def rsync_shared_config
  Chef::Log.info "Rsyncing #{@templates_tmp_root}/shared/config/ with #{@new_resource.host_address}:#{@shared_path}/config/"
  cmd = rsync("#{@templates_tmp_root}/shared/config/",
        "#{@shared_path}/config/",
        @new_resource.host_address,
        @new_resource.ssh_user)
  if cmd.exitstatus == 0
    Chef::Log.info "Rsynced #{@templates_tmp_root}/shared with #{@new_resource.host_address}:#{@shared_path}"
  else
    Chef::Log.warn "Could not rsync #{@templates_tmp_root}/shared with #{@new_resource.host_address}:#{@shared_path}"
    if @new_resource.fail_on_error
      raise "Failing due to fail_on_error setting"
    end
  end
end

def rsync_image_to_release
  Chef::Log.info "Moving #{@new_resource.tmp_dir}/#{@new_resource.host_address}/image to #{@new_resource.host_address}:#{@release_path}/"
  cmd = rsync("#{@new_resource.tmp_dir}/#{@new_resource.host_address}/image/",
        "#{@release_path}/",
        @new_resource.host_address,
        @new_resource.ssh_user)
  if cmd.exitstatus == 0
    Chef::Log.info "Rsynced #{@new_resource.tmp_dir}/#{@new_resource.host_address}/image/ to #{@new_resource.host_address}:#{@release_path}/"
  else
    Chef::Log.warn "Could not rsync #{@new_resource.tmp_dir}/#{@new_resource.host_address}/image/ to #{@new_resource.host_address}:#{@release_path}/"
    if @new_resource.fail_on_error
      raise "Failing due to fail_on_error setting"
    end
  end
end

def render_izpack
  create_dir_unless_exists_local("#{@templates_tmp_root}")

  r = Chef::Resource::Template.new("#{@templates_tmp_root}/controller_izpack.xml", run_context)
  r.path       "#{@templates_tmp_root}/controller_izpack.xml"
  r.source     'controller_izpack.xml.erb'
  r.cookbook   'interactivespaces'
  r.owner      @new_resource.ssh_user
  r.variables  ({:hostname => @new_resource.host_address})
  r.mode       00644
  r.run_action :create
end

def render_config_files
  create_dir_unless_exists_local("#{@templates_tmp_root}/shared/config")
  create_dir_unless_exists_local("#{@templates_tmp_root}/shared/config/interactivespaces")


  files = ["container.conf",
           "interactivespaces/interactivespaces.conf",
           "interactivespaces/controller.conf",
           "interactivespaces/controllerinfo.conf",
           "viewport.conf"]

  files.each do |f|
    r = Chef::Resource::Template.new("#{@templates_tmp_root}/shared/config/#{f}", run_context)
    r.path       "#{@templates_tmp_root}/shared/config/#{f}"
    r.source     "controller/#{f}.erb"
    r.cookbook   'interactivespaces'
    r.owner      @new_resource.ssh_user
    r.mode       00644
    r.variables({
                  :hostname => @new_resource.host_address,
                  :name => "ISCtl#{@new_resource.host_address}",
                  :description => "Interactivespaces controller on #{@new_resource.host_address}"})
    r.run_action :create
  end
end

def fetch_controller_jar
  #FAIL in nice way here if 404
  command = "wget --no-clobber --tries=3 --timeout=10 --waitretry=1 --read-timeout=20 http://galaxy.endpoint.com/interactivespaces/#{@new_resource.version}/controller.jar -O #{@new_resource.tmp_dir}/controller.jar"
  Chef::Log.info "Fetching controller.jar with #{command}"
  shell_out(command)
end

def verify_directories_exist
  create_dir_unless_exists_local(@new_resource.tmp_dir)
  create_dir_unless_exists(@new_resource.deploy_to)
  create_dir_unless_exists(@new_resource.shared_path)
  create_dir_unless_exists("#{@new_resource.deploy_to}/releases")
end

def create_dir_unless_exists_local(dir)
  if ::File.directory?(dir)
    Chef::Log.info "#{@new_resource} not creating #{dir} because it already exists"
    return false
  end
  converge_by("create new directory #{dir}") do
    begin
      FileUtils.mkdir_p(dir)
      Chef::Log.info "#{@new_resource} created directory #{dir}"
      if @new_resource.ssh_user
        FileUtils.chown(@new_resource.ssh_user, nil, dir)
        Chef::Log.info("#{@new_resource} set user to #{@new_resource.ssh_user} for #{dir}")
      end
    rescue => e
      raise Chef::Exceptions::FileNotFound.new("Cannot create directory #{dir}: #{e.message}")
    end
  end
end

def create_dir_unless_exists(dir)
  cmd = run_ssh_command("test -d #{dir}", @new_resource.host_address, @new_resource.ssh_user)
  if cmd.exitstatus == 0
    Chef::Log.info "#{@new_resource} not creating #{dir} because it already exists"
    return false
  elsif cmd.exitstatus == 255
    if @new_resource.fail_on_error == true
      raise "Failing because fail_on_error is set and #{@new_resource.host_address} seems to be unreachable"
    else
      Chef::Log.warn("#{@new_resource.host_address} offline but not raising exception due to fail_on_error set to false")
    end
  end
  converge_by("create new directory #{dir}\n") do
    begin
      cmd = run_ssh_command("mkdir -p #{dir}", @new_resource.host_address, @new_resource.ssh_user)
      if cmd.exitstatus == 0
        Chef::Log.info "#{@new_resource} created directory #{@new_resource.host_address}:#{dir}"
        if @new_resource.user
          cmd = run_ssh_command("chown -R #{@new_resource.user} #{dir}", @new_resource.host_address, @new_resource.ssh_user)
          if cmd.exitstatus == 0
            Chef::Log.info("#{@new_resource} set user to #{@new_resource.user} for #{@new_resource.host_address}:#{dir}")
          else
            Chef::Log.warn("#{@new_resource} Could not set user to #{@new_resource.user} for #{@new_resource.host_address}:#{dir}")
          end
        end
        if @new_resource.group
          cmd = run_ssh_command("chown -R :#{@new_resource.group} #{dir}", @new_resource.host_address, @new_resource.ssh_user)
          if cmd.exitstatus == 0
            Chef::Log.info("#{@new_resource} set group to #{@new_resource.group} for #{@new_resource.host_address}:#{dir}")
          else
            Chef::Log.warn("#{@new_resource} Could not set group to #{@new_resource.group} for #{dir} on #{@new_resource.host_address}")
          end
        end
      end
    rescue => e
      raise Chef::Exceptions::FileNotFound.new("Cannot create directory #{@new_resource.host_address}:#{dir}: #{e.message}")
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
      cmd = run_ssh_command("rm -fr #{failed_release}",
                      @new_resource.host_address,
                      @new_resource.ssh_command)
      if cmd.exitstatus == 0
        Chef::Log.info "Removed failed deploy #{failed_release}"
      end
    end
    release_deleted(failed_release)
  end

  raise
end

def save_release_state
  cmd = run_ssh_command("readlink -f #{@new_resource.current_path}", @new_resource.host_address, @new_resource.ssh_user)
  if cmd.exitstatus == 0
    cmd2 = run_ssh_command("test -d #{cmd.stdout.strip}", @new_resource.host_address, @new_resource.ssh_user)
    if cmd2.exitstatus == 0
      @previous_release_path = cmd.stdout.strip
      Chef::Log.info("Previous release path is #{@previous_release_path} and it exists on #{@new_resource.host_address}")
    end
  end
end

def deployed?(release)
  out = all_releases.include?(@new_resource.version)
  Chef::Log.info("All releases include '#{@new_resource.version}'? => #{out}")
  return out
end

def current_release?(release)
  if host_is_up?(@new_resource.host_address)
    Chef::Log.info("Host #{@new_resource.host_address} is up - checking current release.")
    cmd = run_ssh_command("readlink -f #{@new_resource.current_path}", @new_resource.host_address, @new_resource.ssh_user)
    if cmd.stdout.strip == release
      Chef::Log.info("Host #{@new_resource.host_address} has #{release} deployed to #{cmd.stdout.strip}")
      return true
    else
      Chef::Log.info("Host #{@new_resource.host_address} has not a #{release} deployed to #{cmd.stdout.strip}")
      return false
    end
  else
    Chef::Log.info("Host #{@new_resource.host_address} is not up - not checking current release.")
    if @new_resource.fail_on_error
      raise "Could not check release on #{@new_resource.host_address} because fail_on_error attribute is set"
    end
  end
end

def all_releases
  if host_is_up?(@new_resource.host_address)
    Chef::Log.info("Host #{@new_resource.host_address} is up - listing all releases")
    Chef::Log.info("All_releases command: ls #{@new_resource.deploy_to}/releases")
    cmd = run_ssh_command("ls #{@new_resource.deploy_to}/releases", @new_resource.host_address, @new_resource.ssh_user)
    all = cmd.stdout.split("\n").sort
    Chef::Log.info("All releases: #{all}")
    return all
  else
    Chef::Log.info("Host #{@new_resource.host_address} is not up - not checking current release.")
    if @new_resource.fail_on_error
      raise "Could not check release on #{@new_resource.host_address} because fail_on_error attribute is set"
    end
  end
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
      Chef::Log.info("#{@new_resource} NOT restarting app")
      #shell_out(@new_resource.restart_command, :user => @new_resource.user, :group => @new_resource.group)
    end
  end
end

def link_current_release_to_production
  converge_by(["remove existing link at #{@new_resource.host_address}:#{@new_resource.current_path}",
               "link release #{@new_resource.host_address}:#{@release_path} into production at #{@new_resource.host_address}:#{@new_resource.current_path}"]) do
    run_ssh_command("rm -f #{@new_resource.current_path}", @new_resource.host_address, @new_resource.ssh_user)
    begin
      run_ssh_command("ln -sf #{@release_path} #{@new_resource.current_path}", @new_resource.host_address, @new_resource.ssh_user)
    rescue => e
      raise Chef::Exceptions::FileNotFound.new("Cannot symlink current release to production: #{e.message} (ln -sf #{@release_path} #{@new_resource.current_path})")
    end
    Chef::Log.info "#{@new_resource} linked release #{@new_resource.host_address}:#{@release_path} into production at #{@new_resource.host_address}:#{@new_resource.current_path}"
  end
  enforce_ownership
end

def link_shared_dirs_to_current_release
  links_info = @new_resource.symlinks.join(", ")
  converge_by("make symlinks: #{links_info}") do
    @new_resource.symlinks.each do |symlink|
      begin
        rsync_shared_config
        cmd0 = run_ssh_command("mkdir -p #{@new_resource.shared_path}/#{symlink}",
                                @new_resource.host_address,
                                @new_resource.ssh_user)
        cmd1 = run_ssh_command("rm -fr #{@release_path}/#{symlink}",
                               @new_resource.host_address,
                               @new_resource.ssh_user)
        cmd2 = run_ssh_command("ln -sf #{@new_resource.shared_path}/#{symlink} #{@release_path}/#{symlink}",
                               @new_resource.host_address,
                               @new_resource.ssh_user)
        if cmd0.exitstatus == 0 and cmd1.exitstatus == 0 and cmd2.exitstatus == 0
          Chef::Log.info "#{@new_resource} made symlinks"
        else
          Chef::Log.warn "Could not make symlinks: #{cmd0.inspect}, #{cmd1.inspect}, #{cmd2.inspect}"
          if @new_resource.fail_on_error
            raise Chef::Exceptions::FileNotFound.new("Cannot symlink #{@new_resource.shared_path}/#{symlink} to #{@release_path}/#{symlink} on #{@new_resource.host_address}- #{e.message}")
          end
        end
      rescue => e
        raise Chef::Exceptions::FileNotFound.new("Cannot symlink #{@new_resource.shared_path}/#{symlink} to #{@release_path}/#{symlink} - #{e.message}")
      end
    end
  end
end

def enforce_ownership
  converge_by("force ownership of #{@new_resource.host_address}:#{@new_resource.deploy_to} to #{@new_resource.group}:#{@new_resource.user}") do
    run_ssh_command("sudo chown -R #{@new_resource.user}:#{@new_resource.group} #{@new_resource.deploy_to}",
                    @new_resource.host_address,
                    @new_resource.ssh_user)
    Chef::Log.info("#{@new_resource} set user to #{@new_resource.user} on #{@new_resource.host_address}:#{@new_resource.deploy_to}") if @new_resource.user
    Chef::Log.info("#{@new_resource} set group to #{@new_resource.group} on #{@new_resource.host_address}:#{@new_resource.deploy_to}") if @new_resource.group
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
      run_ssh_command("rm -fr #{i}", @new_resource.host_address, @new_resource.ssh_user)
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

private

def host_is_up?(hostname)
  cmd = shell_out("ping -c 1 -w 1 -- #{hostname}")
  if (cmd.exitstatus == 0 and cmd.stderr.empty?)
    return true
  else
    return false
  end
end

def hosts_are_up?(hostnames) #array
  flag = false
  hostnames.each do |hostname|
    cmd = shell_out("ping -c 1 -w 1 -- #{hostname}")
    if (cmd.exitstatus == 0 and cmd.stderr.empty?)
      flag = true
    else
      return false
    end
  end
  return flag
end

def run_ssh_command(command, hostname, user)
  ssh_cmdline = "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=3"
  cmd = shell_out("#{ssh_cmdline} #{hostname} #{command}", :user => user)
  return cmd
end

def rsync(source_dir, dest_dir, hostname, user)
  cmdline = "rsync -avz -e ssh --delete #{source_dir} #{hostname}:#{dest_dir}"
  Chef::Log.info("Executing rsync: #{cmdline}")
  cmd = shell_out(cmdline, :user => user)
  return cmd
end

