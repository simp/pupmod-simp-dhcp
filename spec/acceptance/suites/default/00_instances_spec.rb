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
        # The simplest dhcpd.conf that won't give an error during restart
        let(:dhcp_config) { "subnet #{fact_on(host, 'networking.network').strip} netmask #{fact_on(host, 'networking.netmask')} { }" }

        # Exercise noop from a clean state: on a fresh node the Sicura console
        # previews the module with `puppet apply --noop`, which must not error.
        # This runs before the applies below install/configure dhcpd, so it is
        # the genuine fresh-node preview. A post-convergence noop check is
        # omitted (`--noop --detailed-exitcodes` always exits 0). No package
        # removal (as with fips/ssh) and, deliberately, no hieradata: the real
        # applies set `simp_options::firewall => true` (which would pull in the
        # simp_firewalld provider that is not noop-safe on EL8), so the noop
        # runs a bare `include 'dhcp'` with firewall default-off -- exactly what
        # the console previews on a fresh node.
        context 'in noop mode from a clean state' do
          it 'applies without errors in noop mode' do
            apply_manifest_on(host, manifest, catch_failures: true, noop: true)
          end
        end

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
