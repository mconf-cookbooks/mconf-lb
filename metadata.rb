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
depends  'mysql2_chef_gem', '~> 1.0'
depends  'mysql', '~> 6.0'
depends  'database', '~> 4.0'
depends  'nodejs', '2.4.2'
depends  'ohai', '2.0.1'
depends  'nginx', '~> 2.7'
depends  'build-essential', '2.0.6'
depends  'heartbeat', '~> 1.0'

recipe 'mconf-lb::default', 'Sets up an instance of Mconf LB'
