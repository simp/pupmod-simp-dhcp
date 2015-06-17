# == Class: dhcp::config
#
# This class is used to configure DHCP for SIMP.
#
# == Parameters
#
# [*rsync_server*]
# Type: FQDN
# Default: hiera('rsync::server')
#   The address of the server from which to pull the DHCPD
#   configuration.
#
# [*rsync_timeout*]
# Type: Integer
# Default: hiera('rsync::timeout','2')
#   The connection timeout when communicating with the rsync server.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
class dhcp::config (
  $rsync_server = $::dhcp::params::rsync_server,
  $rsync_timeout = $::dhcp::params::rsync_timeout
) inherits dhcp::params {
  validate_net_list($rsync_server)
  validate_integer($rsync_timeout)

  include '::dhcp'
  include '::rsync'

  file { '/etc/dhcp':
    ensure    => 'directory',
    owner     => 'root',
    group     => 'root',
    mode      => '0640',
  }

  file { '/etc/dhcp/dhcpd.conf':
    ensure    => 'file',
    owner     => 'root',
    group     => 'root',
    mode      => '0640',
    notify    => Rsync['dhcpd'],
    require   => File['/etc/dhcp']
  }

  file { '/etc/dhcpd.conf':
    ensure    => 'symlink',
    target    => '/etc/dhcp/dhcpd.conf'
  }

  rsync { 'dhcpd':
    user     => 'dhcpd_rsync',
    password => passgen('dhcpd_rsync'),
    server   => $rsync_server,
    timeout  => $rsync_timeout,
    source   => 'dhcpd/dhcpd.conf',
    target   => '/etc/dhcp/dhcpd.conf',
    notify   => Service['dhcpd']
  }
}
