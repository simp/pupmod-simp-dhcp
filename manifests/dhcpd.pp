# == Class: dhcp::dhcpd
#
# This class is used to start dhcpd and create dhcpd.conf
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
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class dhcp::dhcpd (
  $rsync_server = hiera('rsync::server'),
  $rsync_timeout = hiera('rsync::timeout','2')
){
  include 'logrotate'
  include 'rsync'
  include 'rsyslog'

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

  iptables_rule { 'allow_bootp':
    table   => 'filter',
    order   => '11',
    content => '-p udp --dport 67 -j ACCEPT'
  }

  logrotate::add { 'dhcpd':
    log_files  => [ '/var/log/dhcpd.log' ],
    lastaction => '/sbin/service rsyslog restart > /dev/null 2>&1 || true'
  }

  package { 'dhcp': ensure => 'latest' }

  service { 'dhcpd':
    ensure      => 'running',
    enable      => true,
    hasstatus   => true,
    hasrestart  => true,
    require     => [
      File['/etc/dhcpd.conf'],
      Package['dhcp']
    ]
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

  rsyslog::add_rule { '10dhcpd':
    rule    => 'if $programname == \'dhcpd\' then /var/log/dhcpd.log
                & ~'
  }
}
