# Copyright 2014, End Point Corporation
# author: Wojciech Ziniewicz <wojtek@endpoint.com>
#
# LICENSE needed
#
# Creates Interactivespaces Controllers in Master API


node[:interactivespaces][:controllers].each do |controller_name, controller_data|
  interactivespaces_space_controller controller_name do
    name controller_name
    hostid controller_data[:hostid]
    description controller_data[:description]
  end
end
