# == Class: dhcp::service
#
# This class is used to start dhcpd.
#
# == Parameters
#
# == Authors
#
# * Kendall Moore <mailto:kmoore@keywcorp.com>
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
#
class dhcp::service {
  include '::dhcp'

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
}
