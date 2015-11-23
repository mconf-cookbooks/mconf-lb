#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

# User and group on the server the application is being deployed
default['mconf-lb']['user']      = node['mconf']['user'] || 'mconf'
default['mconf-lb']['app_group'] = node['mconf']['app_group'] || 'mconf'

# LB general configurations
default['mconf-lb']['domain']    = '192.168.0.100'
default['mconf-lb']['deploy_to'] = '/var/www/mconf-lb'

# Used for monit's "set daemon"
default['mconf-lb']['monit']['interval'] = 60 # in seconds

# Disable alerts by default
default['mconf-lb']['monit']['enable_alerts'] = false
# Email alerts will be sent with this email as the sender
default['mconf-lb']['monit']['alert_from'] = 'support@foo'
# You can use a single email, an array of emails, or even strings with more parameters, as will be
# passed to monit's "set alert" (see https://mmonit.com/monit/documentation/monit.html).
# Examples:
#   'foo@bar'
#   'foo@bar only on { timeout, nonexist }'
#   ['baz@bar', 'foo@bar only on { timeout, nonexist }']
default['mconf-lb']['monit']['alert_to'] = 'issues@foo'
# SMTP configurations
default['mconf-lb']['monit']['smtp']['server'] = 'smtp.foo'
default['mconf-lb']['monit']['smtp']['port'] = 587
default['mconf-lb']['monit']['smtp']['username'] = 'username'
default['mconf-lb']['monit']['smtp']['password'] = 'password'
default['mconf-lb']['monit']['smtp']['timeout'] = 30
# Stops monitoring after this number of consecutive restarts. Set to 0 to disable
# (will never stop trying).
default['mconf-lb']['monit']['abort_on_restarts'] = 0

# Heartbeat
default['mconf-lb']['heartbeat']['enable'] = false
default['mconf-lb']['heartbeat']['config']['autojoin'] = 'none'
default['mconf-lb']['heartbeat']['config']['deadtime'] = 15
default['mconf-lb']['heartbeat']['config']['initdead'] = 60
default['mconf-lb']['heartbeat']['config']['keepalive'] = 2
default['mconf-lb']['heartbeat']['config']['udpport'] = 694
default['mconf-lb']['heartbeat']['config']['warntime'] = 5
default['mconf-lb']['heartbeat']['config']['authkeys'] = []
default['mconf-lb']['heartbeat']['config']['active_key'] = 1
default['mconf-lb']['heartbeat']['config']['mode'] = :mcast
default['mconf-lb']['heartbeat']['config']['interface'] = ['eth0.5']
default['mconf-lb']['heartbeat']['config']['mcast_group'] = '225.0.0.1'
default['mconf-lb']['heartbeat']['config']['mcast_ttl'] = 1
default['mconf-lb']['heartbeat']['config']['resource_ip'] = 'IPaddr2::192.168.0.0/24/eth0.5/192.168.1.1'

# respawn hacluster /usr/lib/heartbeat/ipfail
# apiauth ipfail gid=haclient uid=hacluster

# If heartbeat is enabled we monitor it using the smallest interval possible
if default['mconf-lb']['heartbeat']['enable']
  default['mconf-lb']['monit']['interval'] = 1
end
