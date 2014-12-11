# Cookbook Name:: interactivespaces
#
# Copyright 2014, End Point Corporation
# author: Wojciech Ziniewicz <wojtek@endpoint.com>
#

include_recipe "java::openjdk"
include_recipe "interactivespaces::tools"
include_recipe "interactivespaces::api_client"
include_recipe "interactivespaces::master"
include_recipe "interactivespaces::controller"
include_recipe "interactivespaces::space_controller"
include_recipe "interactivespaces::activity"
include_recipe "interactivespaces::live_activity"
