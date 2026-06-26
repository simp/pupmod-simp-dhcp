require 'spec_helper_acceptance'

test_name 'dhcpd'

describe 'dhcpd' do
  hosts.each do |_host|
    let(:manifest) do
      <<-EOF
        include 'dhcp'
      EOF
    end
    let(:hieradata) do
      {
        'iptables::ports'         => { 22 => { 'proto' => 'tcp', 'trusted_nets' => ['ALL'] } },
        'simp_options::firewall'  => true,
        'dhcp::dhcpd::dhcpd_conf' => dhcp_config,
      }
    end

    hosts.each do |host|
      context "on #{host}" do
        # The ISC DHCP server (dhcp-server) was retired from RHEL/EL 10 and its
        # rebuilds (and from EPEL 10) in favor of ISC Kea, so there is no
        # dhcp-server package to install on EL10. Skip the package-dependent
        # examples there rather than failing the suite. This is an OS package
        # gap, not a hypervisor limitation, so it is keyed on the OS major.
        el_major = fact_on(host, 'os.release.major').to_i
        dhcp_server_available = el_major < 10

        # The simplest dhcpd.conf that won't give an error during restart
        let(:dhcp_config) { "subnet #{fact_on(host, 'networking.network').strip} netmask #{fact_on(host, 'networking.netmask')} { }" }

        it 'applies with no errors' do
          skip 'ISC dhcp-server is not packaged for EL10 (replaced by ISC Kea)' unless dhcp_server_available
          set_hieradata_on(host, hieradata)
          apply_manifest_on(host, manifest)
        end

        it 'is idempotent' do
          skip 'ISC dhcp-server is not packaged for EL10 (replaced by ISC Kea)' unless dhcp_server_available
          apply_manifest_on(host, manifest, catch_changes: true)
        end
      end
    end
  end
end
