#
# Author:: Wojciech Ziniewicz (<wojtek@endpoint.com>)
#
# Copyright 2014, End Point
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

actions :create
default_action :create

attribute :name, :kind_of => String, :name_attribute => true
attribute :activity_name, :kind_of => String
attribute :controller_name, :kind_of => String
attribute :description, :kind_of => String
attribute :metadata, :kind_of => Hash

attr_accessor :exists
attr_accessor :metadata_up_to_date
