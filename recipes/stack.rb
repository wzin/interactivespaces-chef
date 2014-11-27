# Cookbook Name:: interactivespaces
#
# Copyright 2014, End Point Corporation
# author: Wojciech Ziniewicz <wojtek@endpoint.com>
#
#

interactivespaces_activity 'streetview pano' do
  url 'https://galaxy.endpoint.com/interactivespaces/activities/com.endpoint.lg.streetview.pano-1.0.0.dev.zip'
  action :upload
  name 'Street View Panorama'
  version '1.0.0.dev'
end
