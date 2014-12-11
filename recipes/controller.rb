# Copyright 2014, End Point Corporation
# author: Wojciech Ziniewicz <wojtek@endpoint.com>
#
# LICENSE needed
#
# Deploys Interactivespaces controller

node[:liquid_galaxy][:display_nodes].each do |dispnode|
  interactivespaces_controller node[:interactivespaces][:controller][:deploy][:deploy_to] do
    version node[:interactivespaces][:version]
    host_address dispnode[:hostname]
  end

  files = ["container.conf",
           "interactivespaces/interactivespaces.conf",
           "interactivespaces/controller.conf",
           "interactivespaces/controllerinfo.conf",
           "viewport.conf"]

  files.each do |f|
    template "#{node[:interactivespaces][:controller][:deploy][:templates_tmp_root]}/#{dispnode[:hostname]}/shared/config/#{f}" do
      owner node[:interactivespaces][:controller][:deploy][:ssh_user]
      source "controller/#{f}.erb"
      mode 0644
      only_if {File.directory?("#{node[:interactivespaces][:controller][:deploy][:templates_tmp_root]}/#{dispnode[:hostname]}/shared/config/#{f}")}
      notifies :run, "execute[resync#{dispnode[:hostname]}]", :delayed
      notifies :run, 'execute[relaunch]', :delayed
      variables({:hostname => dispnode[:hostname],
                 :name => "ISCtl#{dispnode[:hostname]}",
                 :description => "Interactivespaces controller on #{dispnode[:hostname]}"})
    end
  end

  execute "resync#{dispnode[:hostname]}" do
    command "echo rsync -e ssh -avz --delete #{node[:interactivespaces][:controller][:deploy][:templates_tmp_root]}/#{dispnode[:hostname]}/shared/config/ #{dispnode[:hostname]}:#{node[:interactivespaces][:controller][:deploy][:deploy_to]}/shared/"
    user node[:interactivespaces][:controller][:deploy][:user]
    action :nothing
  end
end

execute "relaunch" do
  command "echo #{node[:interactivespaces][:controller][:deploy][:restart_cmd]}"
  user node[:interactivespaces][:controller][:deploy][:user]
  action :nothing
end
