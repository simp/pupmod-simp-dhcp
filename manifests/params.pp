# == Class: dhcp::params
#
# This class is used to store the various paramters the DHCP module
# will need to function.
#
# == Authors
#
# * Trevor Vaughan <mailto:tvaughan@onyxpoint.com>
# * Kendall Moore <mailto:kmoore@keywcorp.com>
#
class dhcp::params  {
  $is_client = false
  $is_server = true
  $rsync_server = hiera('rsync::server')
  $rsync_timeout = hiera('rsync::timeout','2')
}
