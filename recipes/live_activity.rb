# Copyright 2014, End Point Corporation
# author: Wojciech Ziniewicz <wojtek@endpoint.com>
#
# LICENSE needed
#
# Creates Interactivespaces live activities


node[:interactivespaces][:live_activities].each do |live_activity_name, live_activity_data|
  interactivespaces_live_activity live_activity_name do
    name live_activity_name
    controller_name live_activity_data[:controller]
    activity_name live_activity_data[:activity]
    metadata live_activity_data[:metadata]
    description live_activity_data[:description]
  end
end
