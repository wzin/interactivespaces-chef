# Copyright 2014, End Point Corporation
# author: Wojciech Ziniewicz <wojtek@endpoint.com>
#
# LICENSE needed
#
# Deploys Interactivespaces Master

interactivespaces_master node[:interactivespaces][:master][:deploy][:deploy_to] do
  version node[:interactivespaces][:version]
end

files = ["container.conf",
         "interactivespaces/interactivespaces.conf",
         "interactivespaces/master.conf"]

files.each do |f|
  template "#{node[:interactivespaces][:master][:deploy][:deploy_to]}/shared/config/#{f}" do
    owner node[:interactivespaces][:master][:deploy][:user]
    group node[:interactivespaces][:master][:deploy][:group]
    source "master/#{f}.erb"
    mode 0644
    only_if {File.directory?("#{node[:interactivespaces][:master][:deploy][:deploy_to]}/shared/config/#{f}")}
    notifies :run, 'execute[relaunch]', :delayed
  end
end

execute "relaunch" do
  command "#{node[:interactivespaces][:master][:deploy][:restart_cmd]}"
  user node[:interactivespaces][:master][:deploy][:user]
  action :nothing
end
