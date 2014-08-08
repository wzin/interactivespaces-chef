# Cookbook Name:: interactivespaces
#
# Copyright 2014, End Point Corporation
# author: Wojciech Ziniewicz <wojtek@endpoint.com>
#

python_pip "requests" do
  action :install
end
package "groovy"
package "unzip"
