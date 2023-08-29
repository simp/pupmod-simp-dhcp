# @summary This class is used to start dhcpd and create dhcpd.conf
#
# @param package_name
#   The DHCP server package name
#
# @param enable_data_rsync
#   Enable the retrieval of the DHCP configuration from an rsync server
#
#   * NOTE: This will be disabled by default at some point in the future
#
# @param rsync_server
#   The address of the server from which to pull the DHCPD
#   configuration
#
# @param rsync_timeout
#   The connection timeout when communicating with the rsync server
#
# @param dhcpd_conf
#   The entire contents of the /etc/dhcpd.conf configuration file
#
#   * If this is set, `$enable_data_rsync` will be forced to `false`
#
# @param firewall
#   Whether or not to include the SIMP iptables class
#
# @param logrotate
#   Whether or not to include the SIMP logrotate class
#
# @param syslog
#   Whether or not to include the SIMP rsyslog class
#
# @param package_ensure The ensure status of the dhcp package
#
# @author https://github.com/simp/pupmod-simp-dhcp/graphs/contributors
#
class dhcp::dhcpd (
  String[1]            $package_name, # In module data
  Optional[String[1]]  $dhcpd_conf        = undef,
  Boolean              $enable_data_rsync = true,
  String[1]            $rsync_source      = "dhcpd_${facts['environment']}_${facts['os']['name']}/dhcpd.conf",
  String[1]            $rsync_server      = simplib::lookup('simp_options::rsync::server', { 'default_value' => '127.0.0.1' }),
  Variant[
    Integer[0],
    Pattern[/\A\d+\z/]
  ]                    $rsync_timeout     = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => '2' }),
  Boolean              $firewall          = simplib::lookup('simp_options::firewall', { 'default_value' => false }),
  Boolean              $logrotate         = simplib::lookup('simp_options::logrotate', { 'default_value' => false }),
  Boolean              $syslog            = simplib::lookup('simp_options::syslog', { 'default_value' => false }),
  String[1]            $package_ensure    = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })
) {

  if $dhcpd_conf {
    $_enable_data_rsync = false
  }
  else {
    $_enable_data_rsync = $enable_data_rsync
  }

  package { $package_name:
    ensure => $package_ensure
  }

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
    seluser => 'system_u',
    seltype => 'dhcp_etc_t',
    content => $dhcpd_conf
  }

  file { '/etc/dhcpd.conf':
    ensure  => 'symlink',
    seluser => 'system_u',
    seltype => 'dhcp_etc_t',
    target  => '/etc/dhcp/dhcpd.conf'
  }

  service { 'dhcpd':
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [
      File['/etc/dhcp/dhcpd.conf'],
      Package[$package_name]
    ]
  }

  if $firewall {
    iptables::listen::udp { 'allow_bootp':
      dports       => [67],
      trusted_nets => ['ALL']
    }
  }

  if $syslog {
    include 'rsyslog'

    rsyslog::rule::local { 'XX_dhcpd':
      rule            => '$programname == \'dhcpd\'',
      target_log_file => '/var/log/dhcpd.log',
      stop_processing => true
    }

    if $logrotate {
      include 'logrotate'

      logrotate::rule { 'dhcpd':
        log_files                 => [ '/var/log/dhcpd.log' ],
        lastaction_restart_logger => true
      }
    }
  }

  if $_enable_data_rsync {
    include 'rsync'

    $_downcase_os_name = downcase($facts['os']['name'])
    rsync { 'dhcpd':
      user      => "dhcpd_rsync_${facts['environment']}_${_downcase_os_name}",
      password  => simplib::passgen("dhcpd_rsync_${facts['environment']}_${_downcase_os_name}"),
      server    => $rsync_server,
      timeout   => $rsync_timeout,
      source    => $rsync_source,
      target    => '/etc/dhcp/dhcpd.conf',
      subscribe => File['/etc/dhcp/dhcpd.conf'],
      notify    => Service['dhcpd']
    }
  }
}
