###
#
#Attributes for interactive spaces
#

is_version = "1.6.2"
is_install_root = "/opt/interactivespaces"

# we need to have interactivespaces-python-api tagged with version of interactivespaces that it's compatibile with
default[:interactivespaces][:ispaces_client][:git_revision] = is_version
default[:interactivespaces][:ispaces_client][:git_clone_url] = "https://github.com/EndPointCorp/interactivespaces-python-api.git"
default[:interactivespaces][:ispaces_client][:logfile_path] = '/home/galadmin/tmp/ispaces-client/ispaces-client.log'
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


