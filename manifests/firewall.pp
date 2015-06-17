# == Class: dhcp::firewall
#
# This class is used to open ports for DHCP in IPTables.
#
# == Parameters
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
class dhcp::firewall {
  include '::dhcp'
  include '::iptables'

  iptables_rule { 'allow_bootp':
    table   => 'filter',
    order   => '11',
    content => '-p udp --dport 67 -j ACCEPT'
  }
}
