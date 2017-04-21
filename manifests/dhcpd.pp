# == Class: dhcp::dhcpd
#
# This class is used to start dhcpd and create dhcpd.conf
#
# == Parameters
#
# [*rsync_server*]
# Type: FQDN
# Default: 127.0.0.1
#   The address of the server from which to pull the DHCPD
#   configuration.
#
# [*rsync_timeout*]
# Type: Integer
# Default: '2'
#   The connection timeout when communicating with the rsync server.
#
# [*firewall*]
# Type: Boolean
# Default: false
# Whether or not to include the SIMP iptables class.
#
# [*logrotate*]
# Type: Boolean
# Default: false
# Whether or not to include the SIMP logrotate class.
#
# [*syslog*]
# Type: Boolean
# Default: false
# Whether or not to include the SIMP rsyslog class.
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class dhcp::dhcpd (
  String                   $rsync_source  = "dhcpd_${::environment}_${facts['os']['name']}/dhcpd.conf",
  String                   $rsync_server  = simplib::lookup('simp_options::rsync::server', { 'default_value'  => '127.0.0.1' }),
  Stdlib::Compat::Integer  $rsync_timeout = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => '2' }),
  Boolean                  $firewall      = simplib::lookup('simp_options::firewall', { 'default_value'       => false }),
  Boolean                  $logrotate     = simplib::lookup('simp_options::logrotate', { 'default_value'      => false }),
  Boolean                  $syslog        = simplib::lookup('simp_options::syslog', { 'default_value'         => false })
){

  include '::rsync'

  package { 'dhcp': ensure => 'latest' }

  file { '/etc/dhcp':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0640',
  }

  file { '/etc/dhcp/dhcpd.conf':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    notify  => Rsync['dhcpd'],
    require => File['/etc/dhcp']
  }

  file { '/etc/dhcpd.conf':
    ensure => 'symlink',
    target => '/etc/dhcp/dhcpd.conf'
  }

  service { 'dhcpd':
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [
      File['/etc/dhcpd.conf'],
      Package['dhcp']
    ]
  }

  $_downcase_os_name = downcase($facts['os']['name'])
  rsync { 'dhcpd':
    user     => "dhcpd_rsync_${::environment}_${_downcase_os_name}",
    password => passgen("dhcpd_rsync_${::environment}_${_downcase_os_name}"),
    server   => $rsync_server,
    timeout  => $rsync_timeout,
    source   => $rsync_source,
    target   => '/etc/dhcp/dhcpd.conf',
    notify   => Service['dhcpd']
  }

  if $firewall {
    iptables::rule { 'allow_bootp':
      table   => 'filter',
      order   => 11,
      content => '-p udp --dport 67 -j ACCEPT'
    }
  }

  if $syslog {
    include '::rsyslog'
    rsyslog::rule::local { 'XX_dhcpd':
      rule            => '$programname == \'dhcpd\'',
      target_log_file => '/var/log/dhcpd.log',
      stop_processing => true
    }
    if $logrotate {
      include '::logrotate'
      logrotate::rule { 'dhcpd':
        log_files                 => [ '/var/log/dhcpd.log' ],
        lastaction_restart_logger => true
      }
    }
  }
}
