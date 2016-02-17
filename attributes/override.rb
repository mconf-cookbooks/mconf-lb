#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

override['build-essential']['compile_time'] = false
override["nodejs"]["install_method"] = "source"
override["nodejs"]["version"] = "0.8.25"
override["nodejs"]["npm"]["install_method"] = "source" # otherwise we can't set the version
override["nodejs"]["npm"]["version"] = "1.3.7"

# Cache the full application path depending on whether capistrano is being used
if node['mconf-lb']['deploy_with_cap']
  override['mconf-lb']['deploy_to_full'] = "#{node['mconf-lb']['deploy_to']}/current"
else
  override['mconf-lb']['deploy_to_full'] = node['mconf-lb']['deploy_to']
end

# Install from source because we need a newer version
nginx_version = "1.6.0"
override["nginx"]["version"] = nginx_version
override["nginx"]["install_method"] = "source"
override["nginx"]["init_style"] = "init"
override["nginx"]["default_site_enabled"] = false
# Something in nginx's recipe makes it use the default version instead of the one we set here, so we
# have to override a few attributes.
# More at: http://stackoverflow.com/questions/17679898/how-to-update-nginx-via-chef
override["nginx"]["source"]["version"] = nginx_version
override["nginx"]["source"]["url"] = "http://nginx.org/download/nginx-#{nginx_version}.tar.gz"
override["nginx"]["source"]["prefix"] = "/opt/nginx-#{nginx_version}"
override['nginx']['source']['default_configure_flags'] = %W(
  --prefix=#{node['nginx']['source']['prefix']}
  --conf-path=#{node['nginx']['dir']}/nginx.conf
  --sbin-path=#{node['nginx']['source']['sbin_path']}
)


# Default options for monit.
# Most of the paths and options here are copied from the defaults in the Ubuntu packages.
override["monit"]["init_style"]             = "upstart"
override["monit"]["config"]["poll_freq"]    = node['mconf-lb']['monit']['interval']
override["monit"]["config"]['start_delay']  = node['mconf-lb']['monit']['start_delay']
override["monit"]["config"]['mail_subject'] = "#{node['mconf-lb']['domain']}: $ACTION $SERVICE ($DESCRIPTION)"
# override["monit"]["config"]['mail_subject'] = "$SERVICE ($ACTION) $EVENT at $DATE"
override["monit"]["config"]['mail_message'] = <<-EOT
Domain: #{node['mconf-lb']['domain']}
Event: $EVENT
Host: $HOST
Service: $SERVICE
Date: $DATE
Action: $ACTION
Description: $DESCRIPTION

Your faithful employee,
Monit
EOT

if node['mconf-lb']['monit']['enable_alerts']
  override["monit"]["config"]['mail_from'] = node['mconf-lb']['monit']['alert_from']

  override["monit"]["config"]["mail_servers"] = [
    {
      "hostname" => node['mconf-lb']['monit']['smtp']['server'],
      "port" => node['mconf-lb']['monit']['smtp']['port'],
      "username" => node['mconf-lb']['monit']['smtp']['username'],
      "password" => node['mconf-lb']['monit']['smtp']['password'],
      "security" => node['mconf-lb']['monit']['smtp']['security'],
      "timeout" => node['mconf-lb']['monit']['smtp']['timeout']
    }
  ]

  if node['mconf-lb']['monit']['alert_to'].kind_of?(Array)
    alerts = node['mconf-lb']['monit']['alert_to']
  elsif node['mconf-lb']['monit']['alert_to'].kind_of?(String)
    alerts = [
      {
        "name" => node['mconf-lb']['monit']['alert_to']
      }
    ]
  else
    alerts = [
      node['mconf-lb']['monit']['alert_to']
    ]
  end
  override["monit"]["config"]["alert"] = alerts
end
