# @summary A selector for configuring the DHCP server or client
#
# The client portion has not yet been implemented.
#
# @param is_client
#   Not yet implemented
#
# @param is_server
#   Denotes that the system is a DHCP server
#
# @author https://github.com/simp/pupmod-simp-dhcp/graphs/contributors
#
class dhcp (
  Boolean $is_client = false,
  Boolean $is_server = true
) {
  if $is_client {
    notify { 'dhcp::client is not yet implemented': }
  }

  if $is_server {
    include 'dhcp::dhcpd'
  }
}
