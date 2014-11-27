node[:interactivespaces][:controllers].each do |controller_name, controller_data|
  interactivespaces_controller controller_name do
    name controller_name
    hostid controller_data[:hostid]
    description controller_data[:description]
  end
end
