#
# Cookbook Name:: mconf-lb
# Recipe:: default
# Author:: Leonardo Crauss Daronco (<daronco@mconf.org>)
#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

execute "apt-get update"

include_recipe "build-essential"

%w{git libssl-dev libgeoip-dev libexpat1-dev}.each do |pkg|
  package pkg
end


# Create the app directory
# (Just the directory, capistrano does the rest)

directory node['mconf-lb']['deploy_to'] do
  owner node['mconf-lb']['user']
  group node['mconf-lb']['app_group']
  mode '0755'
  recursive true
  action :create
end


# Node.js
include_recipe "nodejs"
include_recipe "nodejs::npm"

# change the default npm directory so we're sure it is used only for npm
# the default is ~/npm, but that might be too generic
execute "npm config set tmp /home/#{node[:mconf][:user]}/npmtmp"

# Npm is installed as root and ~/.npm ends up being owned by root, but it shouldn't.
# Newer versions of node/npm might not need this anymore.
# See: https://github.com/npm/npm/issues/3350
execute "sudo rm -R /home/#{node[:mconf][:user]}/.npm" do
  not_if { !::File.exists?("/home/#{node[:mconf][:user]}/.npm") }
end
execute "sudo rm -R /home/#{node[:mconf][:user]}/npmtmp" do
  not_if { !::File.exists?("/home/#{node[:mconf][:user]}/npmtmp") }
end


# Nginx installation

# TODO: it is apparently always compiling and restarting nginx, shouldn't do it
# all the time
include_recipe "nginx"
service "nginx"

## alternative: install from a PPA
# node.set["nginx"]["version"] = "1.6.0"
# node.set["nginx"]["install_method"] = "package"
# apt_repository "nginx" do
#   uri "http://ppa.launchpad.net/nginx/stable/ubuntu"
#   components ["precise", "main"]
#   keyserver "keyserver.ubuntu.com"
#   key "C300EE8C"
# end
# execute "apt-get update"
# include_recipe "nginx"

# Nginx configurations
directory "/etc/nginx/includes" do
  owner "root"
  group "root"
  mode 00755
  action :create
end

cookbook_file "/etc/nginx/includes/mconf-lb-proxy.conf" do
  source "nginx-include.conf"
  mode 00644
  owner "root"
  group "root"
  notifies :restart, "service[nginx]", :delayed
end

template "/etc/nginx/sites-available/mconf-lb" do
  source "nginx-site.erb"
  mode 00644
  owner "root"
  group "root"
  variables({
    :domain => node["mconf-lb"]["domain"]
  })
  notifies :restart, "service[nginx]", :delayed
end

execute "nxensite mconf-lb" do
  creates "/etc/nginx/sites-enabled/mconf-lb"
  notifies :restart, "service[nginx]", :delayed
end


# Upstart
template "/etc/init/mconf-lb.conf" do
  source "upstart-script.conf.erb"
  mode 00644
  owner "root"
  group "root"
end


# Monit
# TODO: can we set an specific version?
package "monit"
service "monit"

template "/etc/monit/conf.d/mconf-lb" do
  source "monit-mconflb.erb"
  mode 00644
  owner "root"
  group "root"
  variables(
    cycle_multiplier: node['mconf-lb']['heartbeat']['enable'] ? 60 : 1,
    abort_on_restarts: node['mconf-lb']['monit']['abort_on_restarts']
  )
  notifies :restart, "service[monit]", :delayed
end

template "/etc/monit/monitrc" do
  source "monitrc.erb"
  mode 00600
  owner "root"
  group "root"
  notifies :restart, "service[monit]", :delayed
end


# logrotate
# TODO: use logrotate_app to configure this logrotate
template "/etc/logrotate.d/mconf-lb" do
  source "logrotate-config.erb"
  mode 00644
  owner "root"
  group "root"
end
execute "logrotate -s /var/lib/logrotate/status /etc/logrotate.d/mconf-lb"


# Heartbeat
if node['mconf-lb']['heartbeat']['enable']
  include_recipe "heartbeat"

  resource_grp = ::Chef::Resource::HeartbeatResourceGroup.new(run_context, cookbook_name, recipe_name)
  resource_grp.ipaddr node['mconf-lb']['heartbeat']['config']['resource_ip']
  resource_grp.default_node node['mconf-lb']['heartbeat']['config']['default_node']
  heartbeat "heartbeat" do
    auto_failback node['mconf-lb']['heartbeat']['config']['auto_failback']
    autojoin node['mconf-lb']['heartbeat']['config']['autojoin']
    compression node['mconf-lb']['heartbeat']['config']['compression']
    compression_threshold node['mconf-lb']['heartbeat']['config']['compression_threshold']
    deadtime node['mconf-lb']['heartbeat']['config']['deadtime']
    initdead node['mconf-lb']['heartbeat']['config']['initdead']
    keepalive node['mconf-lb']['heartbeat']['config']['keepalive']
    logfacility node['mconf-lb']['heartbeat']['config']['logfacility']
    udpport node['mconf-lb']['heartbeat']['config']['udpport']
    warntime node['mconf-lb']['heartbeat']['config']['warntime']
    search node['mconf-lb']['heartbeat']['config']['search']
    authkeys node['mconf-lb']['heartbeat']['config']['authkeys']
    active_key node['mconf-lb']['heartbeat']['config']['active_key']
    mode node['mconf-lb']['heartbeat']['config']['mode']
    interface node['mconf-lb']['heartbeat']['config']['interface']
    mcast_group node['mconf-lb']['heartbeat']['config']['mcast_group']
    mcast_ttl node['mconf-lb']['heartbeat']['config']['mcast_ttl']
    resource_groups [resource_grp]
    nodes node['mconf-lb']['heartbeat']['config']['nodes']
  end

  # Monit configs for heartbeat
  template '/etc/monit/conf.d/mconf-lb-pid' do
    source 'monit-mconflbpid.erb'
    mode 00644
    owner 'root'
    group 'root'
    notifies :restart, "service[monit]", :delayed
  end

  template '/etc/monit/conf.d/mconf-lb-heartbeat' do
    source 'monit-heartbeat.erb'
    mode 00644
    owner 'root'
    group 'root'
    notifies :restart, "service[monit]", :delayed
  end
end
