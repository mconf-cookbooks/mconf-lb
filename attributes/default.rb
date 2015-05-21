#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

# User and group on the server the application is being deployed
default['mconf']['user'] = 'mconf'
default['mconf']['app_group'] = 'www-data'

# LB general configurations
default['mconf-lb']['domain'] = '192.168.0.100'
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

# Heartbeat
default['heartbeat']['enable'] = false
default['heartbeat']['config']['autojoin'] = 'none'
default['heartbeat']['config']['deadtime'] = 15
default['heartbeat']['config']['initdead'] = 60
default['heartbeat']['config']['keepalive'] = 2
default['heartbeat']['config']['udpport'] = 694
default['heartbeat']['config']['warntime'] = 5
default['heartbeat']['config']['authkeys'] = []
default['heartbeat']['config']['active_key'] = 1
default['heartbeat']['config']['mode'] = :mcast
default['heartbeat']['config']['interface'] = ['eth0.5']
default['heartbeat']['config']['mcast_group'] = '225.0.0.1'
default['heartbeat']['config']['mcast_ttl'] = 1
default['heartbeat']['config']['resource_ip'] = 'IPaddr2::192.168.0.0/24/eth0.5/192.168.1.1'

# respawn hacluster /usr/lib/heartbeat/ipfail
# apiauth ipfail gid=haclient uid=hacluster

# If heartbeat is enabled we monitor it using the smallest interval possible
if default['heartbeat']['enable']
  default['mconf-lb']['monit']['interval'] = 1
end
