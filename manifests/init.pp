# == Class: dhcp
#
# This class provides an input selector for configuring the DHCP
# server or client.
#
# The client portion has not yet been implemented.
#
# Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class dhcp (
  $is_client = false,
  $is_server = true
){
  validate_bool($is_client)
  validate_bool($is_server)

  if $is_client {
    notify { 'dhcp::client is not yet implemented': }
  }

  if $is_server {
    include 'dhcp::dhcpd'
  }
}
