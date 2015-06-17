# == Class: dhcp::logging
#
# This class is used to define RSyslog rules for DHCP.
#
# == Parameters
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
class dhcp::logging {
  include '::dhcp'
  include '::logrotate'
  include '::rsyslog'

  rsyslog::rule::local { '10dhcpd':
    rule    => 'if $programname == \'dhcpd\' then /var/log/dhcpd.log & stop'
  }

  logrotate::add { 'dhcpd':
    log_files  => [ '/var/log/dhcpd.log' ],
    lastaction => '/sbin/service rsyslog restart > /dev/null 2>&1 || true'
  }
}
