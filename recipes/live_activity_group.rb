node[:interactivespaces][:live_activity_groups].each do |live_activity_group_name, live_activity_group_data|
  interactivespaces_live_activity_group live_activity_group_name do
    name live_activity_group_name
    metadata live_activity_group_data[:metadata]
    live_activities live_activity_group_data[:live_activities]
    description live_activity_group_data[:description]
  end
end
