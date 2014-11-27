###
#
#Attributes for interactive spaces
#

is_version = "1.6.2"
is_install_root = "/opt/interactivespaces"

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
default[:interactivespaces][:ispaces_client][:launch_command]="tmux new -s ISController -d '#{is_install_root}/controller/bin/startup_linux.bash'"
default[:interactivespaces][:ispaces_client][:stop_command]="kill `cat #{is_install_root}/controller/run/interactivespaces.pid`"
default[:interactivespaces][:ispaces_client][:pid_command]="tmux new -s ISController -d '#{is_install_root}/controller/bin/startup_linux.bash'"
default[:interactivespaces][:ispaces_client][:destroy_tmux_command]='tmux kill-session -t ISController'
default[:interactivespaces][:ispaces_client][:master_launch_command]="tmux new -s ISMaster -d '#{is_install_root}/master/bin/startup_linux.bash'"
default[:interactivespaces][:ispaces_client][:master_stop_command]="kill `cat #{is_install_root}/master/run/interactivespaces.pid`"
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
