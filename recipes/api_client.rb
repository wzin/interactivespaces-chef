# Copyright 2014, End Point Corporation
# author: Wojciech Ziniewicz <wojtek@endpoint.com>
#
# LICENSE needed
#
# Deploys Interactivespaces API client library and tools

directory "/home/galadmin/tmp/ispaces-client" do
  mode 0755
  group "galadmin"
  user "galadmin"
end

git "/home/galadmin/src/interactivespaces-python-api" do
  repository node[:interactivespaces][:ispaces_client][:git_clone_url]
  revision   node[:interactivespaces][:ispaces_client][:git_revision]
  action      :sync
  user "galadmin"
end

relaunch_sequence = node[:interactivespaces][:ispaces_client][:relaunch_sequence].join(',')
display_nodes_list = []
display_nodes = []

node[:liquid_galaxy][:display_nodes].each do |display_node|
  controller_name = display_node[:ispaces_controller_name] || "ISCtl#{display_node[:hostname].gsub('-','')}"
  display_nodes_list << { 'hostname' => display_node['hostname'],
                          'ispaces_controller_name' => controller_name }
  display_nodes << display_node['hostname']
end

display_nodes = display_nodes.join(',')

template "/home/galadmin/etc/ispaces-client.conf" do
  source "ispaces-client.conf.erb"
  owner "galadmin"
  group "galadmin"
  mode 0644
  variables(
    :relaunch_sequence => relaunch_sequence,
    :display_nodes_list => display_nodes_list,
    :display_nodes => display_nodes
  )
end

link "/home/galadmin/bin/ispaces-relaunch.py" do
  only_if "test -f /home/galadmin/src/interactivespaces-python-api/scripts/ispaces-relaunch.py"
  to "/home/galadmin/src/interactivespaces-python-api/scripts/ispaces-relaunch.py"
  owner "galadmin"
  group "galadmin"
end

link "/home/galadmin/bin/lg-relaunch" do
  only_if "test -f /home/galadmin/src/interactivespaces-python-api/scripts/ispaces-relaunch.py"
  to "/home/galadmin/src/interactivespaces-python-api/scripts/ispaces-relaunch.py"
  owner "galadmin"
  group "galadmin"
end

#File.lchmod is unimplemented on this OS and Ruby version
execute "Change /home/galadmin/bin/ispaces-relaunch.py permissions" do
  command "chmod 755 /home/galadmin/bin/ispaces-relaunch.py"
  user "galadmin"
  group "galadmin"
end
