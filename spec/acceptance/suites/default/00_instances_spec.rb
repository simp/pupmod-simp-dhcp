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
        'iptables::ports' => { 22 => { 'proto' => 'tcp', 'trusted_nets' => ['ALL'] } },
     'simp_options::firewall'  => true,
     'dhcp::dhcpd::dhcpd_conf' => dhcp_config
      }
    end

    hosts.each do |host|
      context "on #{host}" do
        # The simplest dhcpd.conf that won't give an error during restart
        let(:dhcp_config) { "subnet #{fact_on(host, 'networking.network').strip} netmask #{fact_on(host, 'networking.netmask')} { }" }

        it 'applies with no errors' do
          set_hieradata_on(host, hieradata)
          apply_manifest_on(host, manifest)
        end

        it 'is idempotent' do
          apply_manifest_on(host, manifest, catch_changes: true)
        end
      end
    end
  end
end
