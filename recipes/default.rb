#
# Cookbook Name:: iscsi
# Recipe:: default
#
# Copyright 2010, Gerald L. Hevener, Jr, M.S.
# Copyright 2010, Erig G. Wolfe
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

include_recipe 'sysctl'

node['iscsi']['packages'].each do |iscsi_package|
  package iscsi_package
end

template '/etc/iscsi/iscsid.conf' do
  source 'iscsid.conf.erb'
  owner 'root'
  group 'root'
  mode 00600
end

template "/etc/iscsi/initiatorname.iscsi" do
  source "initiatorname.iscsi.erb"
  owner "root"
  group "root"
  mode "0640"
  action :create
  variables(
     :short_hostname => node['hostname']
  )
end

execute 'udev_reload_rules' do
  command node['iscsi']['udev']['reload_command']
  action :nothing
end

template '/etc/udev/rules.d/50-ethtool.rules' do
  source '50-ethtool.rules.erb'
  owner 'root'
  group 'root'
  mode 00644
  notifies :run, 'execute[udev_reload_rules]'
end

%w(iscsid iscsi netfs).each do |iscsi_subsys|
  service iscsi_subsys do
    supports status: true, restart: true
    action [:enable, :start]
  end
end


# Setup the ethernet interfaces used by ISCSI
# We only do this configuration if the network interfaces are defined
if node["iscsi"].attribute?("network_interfaces")
  for nic, nic_info in node["iscsi"]["network_interfaces"]
    ifconfig nic_info["ipaddr"] do
      device nic
      mask nic_info["netmask"]
      onboot "yes"
      mtu "9000"
      bootproto "static"
    end
  end
end