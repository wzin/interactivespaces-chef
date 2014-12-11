###
#
#Attributes for interactive spaces
#

# => Master + Controller deployment
default[:interactivespaces][:version] = "1.7.1"
default[:interactivespaces][:master][:hostname] = 'lg-head'
is_version = default[:interactivespaces][:version]

# Master deployment
default[:interactivespaces][:master][:deploy][:deploy_to] = "/opt/interactivespaces/master"
default[:interactivespaces][:master][:deploy][:user] = "galadmin"
default[:interactivespaces][:master][:deploy][:group] = "galadmin"
default[:interactivespaces][:master][:deploy][:symlinks] = ["logs", "config", "run"]
default[:interactivespaces][:master][:deploy][:tmp_dir] = "/tmp/ispaces_master_tmp"
default[:interactivespaces][:master][:deploy][:restart_cmd] = "/home/galadmin/bin/lg-relaunch --full-relaunch --config=/home/galadmin/etc/ispaces-client.conf"

# Controller deployment
#determines whether chef should throw an error if host, on which controller should be deployed, is offline.
default[:interactivespaces][:controller][:deploy][:fail_on_error] = false
default[:interactivespaces][:controller][:deploy][:deploy_to] = "/opt/interactivespaces/controller"
default[:interactivespaces][:controller][:deploy][:templates_tmp_root] = "/opt/interactivespaces/disp"
default[:interactivespaces][:controller][:deploy][:ssh_user] = "galadmin"
default[:interactivespaces][:controller][:deploy][:user] = "lg"
default[:interactivespaces][:controller][:deploy][:group] = "lg"
default[:interactivespaces][:controller][:deploy][:symlinks] = ["logs", "config", "run"]
default[:interactivespaces][:controller][:deploy][:tmp_dir] = "/tmp/ispaces_controller_tmp"
default[:interactivespaces][:controller][:deploy][:restart_cmd] = "/home/galadmin/bin/lg-relaunch --full-relaunch --config=/home/galadmin/etc/ispaces-client.conf"

is_master_install_root = default[:interactivespaces][:master][:deploy][:deploy_to]
is_controller_install_root = default[:interactivespaces][:controller][:deploy][:deploy_to]

# => Binary management - controllers and master

# => interactivespaces client configuration
#
# we need to have interactivespaces-python-api tagged with version of interactivespaces that it's compatibile with
# ispaces_client configuration below

default[:interactivespaces][:ispaces_client][:git_revision] = is_version
default[:interactivespaces][:ispaces_client][:git_clone_url] = "https://github.com/EndPointCorp/interactivespaces-python-api.git"
default[:interactivespaces][:ispaces_client][:logfile_path] = '/home/galadmin/tmp/ispaces-client/ispaces-client.log'
default[:interactivespaces][:ispaces_client][:configfile_path] = '/home/galadmin/etc/ispaces-client.cfg'
default[:interactivespaces][:ispaces_client][:relaunch_sequence] = []
default[:interactivespaces][:ispaces_client][:master_http_port] = "8080"
default[:interactivespaces][:ispaces_client][:master_host] = "127.0.0.1"
default[:interactivespaces][:ispaces_client][:relaunch][:shutdown_attempts] = 5
default[:interactivespaces][:ispaces_client][:relaunch][:startup_attempts] = 2
default[:interactivespaces][:ispaces_client][:relaunch][:interval_between_attempts] = 5
default[:interactivespaces][:ispaces_client][:relaunch][:relaunch_controllers] = 0 #using 0 || 1 because python/ruby have different bool symbols
default[:interactivespaces][:ispaces_client][:relaunch][:relaunch_master] = 0
default[:interactivespaces][:ispaces_client][:ssh_command] = "ssh -t -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=3"
default[:interactivespaces][:ispaces_client][:launch_command]="tmux new -s ISController -d '#{is_controller_install_root}/current/bin/startup_linux.bash'"
default[:interactivespaces][:ispaces_client][:stop_command]="kill `cat #{is_controller_install_root}/current/run/interactivespaces.pid`"
default[:interactivespaces][:ispaces_client][:pid_command]="tmux new -s ISController -d '#{is_controller_install_root}/current/bin/startup_linux.bash'"
default[:interactivespaces][:ispaces_client][:destroy_tmux_command]='tmux kill-session -t ISController'
default[:interactivespaces][:ispaces_client][:master_launch_command]="tmux new -s ISMaster -d '#{is_master_install_root}/current/bin/startup_linux.bash'"
default[:interactivespaces][:ispaces_client][:master_stop_command]="kill `cat #{is_master_install_root}/current/run/interactivespaces.pid`"
default[:interactivespaces][:ispaces_client][:master_destroy_tmux_command]='tmux kill-session -t ISMaster'

# IS Master API attributes below
=begin
Example node attributes:

{
  "interactivespaces": {
    "ispaces_client": {
      "relaunch_sequence": [
        "Pre-Start",
        "Google Earth",
        "Street View",
        "Liquid Galaxy"
      ]
    },
    "activities": {
      "Street View Panorama": {
        "url": "https://galaxy.endpoint.com/interactivespaces/activities/com.endpoint.lg.streetview.pano-1.0.0.dev.zip",
        "version ": "1.0.0dev"
      }
    },
    "live_activities": {
      "SV Pano on 42-a": {
        "controller": "ISCtl42a",
        "initial_state": "deploy - not yet used",
        "description": "some description",
        "activity": "Street View Panorama",
        "metadata": {
          "lg.svpano.some_key": "some_value",
          "some_other_key": "some_other_value"
        }
      }
    },
    "controllers": {
      "ISCtl42a": {
        "description": "some fancy controller description",
        "hostid": "isctl42a"
      }
    },
    "live_activity_groups": {
      "live_activity_group_name": {
        "live_activities": [
          {
            "live_activity_name": "some_name",
            "space_controller_name": "some_name"
          }
        ],
        "live_activity_group_name": "some_name",
        "metadata": {
          "key": "value"
        }
      }
    }
  }
}

=end

default[:interactivespaces][:activities] = []
default[:interactivespaces][:live_activities] = []
default[:interactivespaces][:controllers] = []
default[:interactivespaces][:live_activity_groups] = []
default[:interactivespaces][:spaces] = []
