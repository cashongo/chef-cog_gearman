#
# Cookbook Name:: gearmand
# Recipe:: install
#
# Copyright (C) 2014 Cash on Go Ltd.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "build-essential"
include_recipe "cog_gearmand::build-addition"

version = node['gearman']['version']

remote_file_path = "#{Chef::Config[:file_cache_path]}/gearmand-#{version}.tar.gz"

remote_file remote_file_path do
    source "#{node['gearman']['source']}/#{node['gearman']['series']}/#{version}/+download/gearmand-#{version}.tar.gz"
    mode "0644"
    action :nothing
end

bash "build_gearman" do
    user "root"
    cwd Chef::Config[:file_cache_path]
    code <<-EOF
    tar -zxvf gearmand-#{version}.tar.gz
    cd gearmand-#{version} && ./configure && make && make install
    EOF
    action :nothing
end

bash "export_path" do
    user "root"
    code <<-EOF
    if ! [[ "$PATH" == */usr/local/bin* ]]
    then
    export PATH=$PATH:/usr/local/bin;
    fi
    EOF
    action :nothing
end

ruby_block "check_gearman_version" do
    block do
        current_version = ""
        begin
            current_version = `gearmand -V | cut -d" " -f2`
        rescue
        end
        
        current_version = current_version.strip if current_version.is_a?(String)

        unless version == current_version
            notifies :create, resources(:remote_file => remote_file_path), :immediately
            notifies :run, resources(:bash => "build_gearman"), :immediately
            notifies :run, resources(:bash => "export_path"), :immediately
        end
    end
end