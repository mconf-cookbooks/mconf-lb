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

include_recipe "apt"

include_recipe "build-essential"

%w{git libssl-dev libgeoip-dev libexpat1-dev}.each do |pkg|
  package pkg
end

# Create the app directory
# (Just the directory, capistrano does the rest)
directory node['mconf-lb']['deploy_base'] do
  owner node['mconf-lb']['user']
  group node['mconf-lb']['app_group']
  mode '0755'
  recursive true
  action :create
end

# Node.js
include_recipe "nodejs"
include_recipe "nodejs::npm"

# disable the site in nginx temporarily so it doesn't break the
# rest of the installation if it's incorrect
execute "nxdissite mconf-lb" do
  ignore_failure true
end

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

# Certificates for nginx
if node['mconf-lb']['ssl']['enable']
  directory node['mconf-lb']['ssl']['certificates']['path'] do
    owner 'root'
    group node['mconf-lb']['app-group']
    mode 00640
    recursive true
    action :create
  end

  certs = {
    certificate_file: nil,
    certificate_key_file: nil
  }
  certs.each do |cert_name, value|
    file = node['mconf-lb']['ssl']['certificates'][cert_name]
    if file && file.strip != ''
      path = "#{node['mconf-lb']['ssl']['certificates']['path']}/#{file}"
      cookbook_file path do
        source file
        owner 'root'
        group node['mconf-lb']['app-group']
        mode 00640
        action :create
        notifies :restart, "service[nginx]", :delayed
        only_if { run_context.has_cookbook_file_in_cookbook?('mconf-lb', file) }
      end
    end
    certs[cert_name] = path
  end
  node.run_state['mconf-lb-certs'] = certs

  # see https://gist.github.com/plentz/6737338
  dhp_2048_file = '/etc/nginx/ssl/dhp-2048.pem'
  execute "openssl dhparam -out #{dhp_2048_file} 2048" do
    not_if { ::File.exists?(dhp_2048_file) }
  end
end

directory "/etc/nginx/includes" do
  owner "root"
  group "root"
  mode 00755
  action :create
end

# remove the old include file, if it exists
file "/etc/nginx/includes/mconf-lb-proxy.conf" do
  action :delete
end

template "/etc/nginx/sites-available/mconf-lb" do
  source "nginx-site.erb"
  mode 00644
  owner "root"
  group "root"
  variables({
    domain: node["mconf-lb"]["domain"],
    deploy_to: node["mconf-lb"]["deploy_to"],
    ssl: node["mconf-lb"]["ssl"]["enable"],
    ssl_http_api: node["mconf-lb"]["ssl"]["http_api"],
    use_custom_log: node["mconf-lb"]["nginx"]["custom_log_format"] != nil,
    certificates: node.run_state["mconf-lb-certs"],
    tmp_redirect_api: node["mconf-lb"]["tmp-redirect-api"]
  })
  notifies :restart, "service[nginx]", :delayed
end

execute "nxensite mconf-lb" do
  creates "/etc/nginx/sites-enabled/mconf-lb"
  notifies :restart, "service[nginx]", :delayed
end

# logrotate for nginx (the cookbook doesn't configure it, we're not
# overriding it)
# this is mostly based on the config used by a newer version of the
# cookbook nginx, see:
# https://github.com/miketheman/nginx/blob/cdc31cd03606c5ae1914c7fbc93b2a7635647cd2/templates/default/nginx.logrotate.erb
logrotate_app 'nginx' do
  cookbook 'logrotate'
  path ["#{node['nginx']['log_dir']}/*.log"]
  options ['missingok', 'compress', 'copytruncate', 'notifempty', 'dateext']
  frequency node['mconf-lb']['nginx']['logrotate']['frequency']
  rotate node['mconf-lb']['nginx']['logrotate']['rotate']
  size node['mconf-lb']['nginx']['logrotate']['size']
  create "0600 root root"
  sharedscripts
  prerotate <<-EOF
    if [ -d /etc/logrotate.d/httpd-prerotate ]; then \\
      run-parts /etc/logrotate.d/httpd-prerotate; \\
    fi;
  EOF
  postrotate <<-EOF
    [ ! -f #{node['nginx']['pid']} ] || kill -USR1 `cat #{node['nginx']['pid']}`
  EOF
end


# Service
# Note: we don't use a "service mconf-lb" here because the application is started
# and stopped by monit and by capistrano with restart.txt
if node['mconf-lb']['use_systemd']
  template "/etc/systemd/system/mconf-lb.service" do
    source "systemd-mconf-lb.service.erb"
    mode 00644
    owner "root"
    group "root"
    variables(
      pidfile: node['mconf-lb']['pidfile']
    )
  end
  service "mconf-lb" do
    action :enable
  end
else
  template "/etc/init/mconf-lb.conf" do
    source "upstart-script.conf.erb"
    mode 00644
    owner "root"
    group "root"
  end
end


# Monit
include_recipe "monit-ng"

template "#{node["monit"]["conf_dir"]}/mconf-lb.conf" do
  source "monit-mconf-lb.conf.erb"
  mode 00644
  owner "root"
  group "root"
  variables(
    cycle_multiplier: node['mconf-lb']['heartbeat']['enable'] ? 60 : 1,
    abort_on_restarts: node['mconf-lb']['monit']['abort_on_restarts']
  )
  notifies :restart, "service[monit]", :delayed
end

# logrotate
logrotate_app 'mconf-lb' do
  cookbook 'logrotate'
  path ["#{node['mconf-lb']['deploy_to']}/log/*.log"]
  options ['missingok', 'compress', 'copytruncate', 'notifempty', 'dateext']
  frequency node['mconf-lb']['logrotate']['frequency']
  rotate node['mconf-lb']['logrotate']['rotate']
  size node['mconf-lb']['logrotate']['size']
  create "0600 #{node['mconf-lb']['user']} #{node['mconf-lb']['app_group']}"
end

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
  template "#{node["monit"]["conf_dir"]}/mconf-lb-pid.conf" do
    source "monit-mconf-lb-pid.conf.erb"
    mode 00644
    owner 'root'
    group 'root'
    notifies :restart, "service[monit]", :delayed
  end

  template "#{node["monit"]["conf_dir"]}/mconf-lb-heartbeat.conf" do
    source "monit-mconf-lb-heartbeat.conf.erb"
    mode 00644
    owner 'root'
    group 'root'
    notifies :restart, "service[monit]", :delayed
  end
end
