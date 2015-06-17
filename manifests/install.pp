# == Class: dhcp::install
#
# This class is used to install DHCP.
#
# == Parameters
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class dhcp::install inherits dhcp::params {
  include '::dhcp'
  package { 'dhcp': ensure => 'latest' }
}
