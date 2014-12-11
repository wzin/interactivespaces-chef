# LICENSE needed
#
# Deploys Interactivespaces Activity

node[:interactivespaces][:activities].each do |activity_name, activity_data|
  interactivespaces_activity activity_name do
    name activity_name
    url  activity_data[:url]
    version activity_data[:version]
  end
end
