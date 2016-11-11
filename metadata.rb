#
# This file is part of the Mconf project.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

name             'mconf-lb'
maintainer       'mconf'
maintainer_email 'mconf@mconf.org'
license          'MPL v2.0'
description      'Sets up an instance of Mconf LB'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports 'ubuntu', '>= 14.04'

suggests 'mconf-db'
depends  'mysql', '~> 6.0'
depends  'database', '~> 4.0'
depends  'nodejs', '~> 3.0'
depends  'ohai', '2.0.1'
depends  'build-essential', '>= 2.0'
depends  'heartbeat', '~> 1.0'
depends  'monit-ng', '~> 2.1.0'
depends  'logrotate', '~> 1.9'
depends  'apt', '>= 2.9'

# TODO: update to 3.0 when done, 2.x is old
depends  'nginx', '~> 2.7'

recipe 'mconf-lb::default', 'Sets up an instance of Mconf LB'
