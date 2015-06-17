# == Class: dhcp
#
# This class sets up a DHCP server by configuring and initializing dhcpd.
# 
# TODO: Support client-side DHCP configurtation.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
class dhcp (
  $is_client = $::dhcp::params::is_client,
  $is_server = $::dhcp::params::is_server
) inherits dhcp::params {
  validate_bool($is_client)
  validate_bool($is_server)

  if $is_client {
    notify { 'dhcp::client is not yet implemented': }
  }

  if $is_server {
    include '::dhcp::install'
    include '::dhcp::config'
    include '::dhcp::service'

    Class['dhcp::install'] ~>
    Class['dhcp::config'] ~>
    Class['dhcp::service']

    if $::use_iptables or hiera('use_iptables') {
      include '::dhcp::firewall'
      Class['dhcp::service'] -> Class['dhcp::firewall']
    }

    if $::use_simp_logging or hiera('use_simp_logging') {
      include '::dhcp::logging'
      Class['dhcp::service'] -> Class['dhcp::logging']
    }
  }
}
