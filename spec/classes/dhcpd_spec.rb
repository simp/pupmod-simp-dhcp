require 'spec_helper'

describe 'dhcp::dhcpd' do

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end

      context "on #{os}" do
        let(:environment){:foo}
        context 'in the :foo environment' do

          it { is_expected.to create_class('dhcp::dhcpd') }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_package('dhcp').with_ensure('latest') }
          it { is_expected.to contain_service('dhcpd').with({
              :ensure  =>'running',
              :require => ['File[/etc/dhcpd.conf]', 'Package[dhcp]']
            })
          }
          it { is_expected.to create_file('/etc/dhcp').with_ensure('directory') }
          it { is_expected.to create_file('/etc/dhcp/dhcpd.conf').with({
              :ensure  => 'file',
              :notify  => 'Rsync[dhcpd]',
              :require => 'File[/etc/dhcp]'
            })
          }
          it { is_expected.to create_file('/etc/dhcpd.conf').with({
              :ensure => 'symlink',
              :target => '/etc/dhcp/dhcpd.conf'
            })
          }
          it { is_expected.to contain_rsync('dhcpd').with({
              :source => "dhcpd_#{environment}/dhcpd.conf"
            })
          }
          it { is_expected.to_not create_iptables__rule('allow_bootp') }
          it { is_expected.to_not create_logrotate__rule('dhcpd') }
          it { is_expected.to_not contain_rsyslog__rule__local ( 'XX_dhcpd' ) }
        end

        context 'with firewall => true, syslog => true, logrotate => true' do
	  let(:params) {{:firewall => true, :syslog => true, :logrotate => true }}
          it { is_expected.to create_class('dhcp::dhcpd') }
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_iptables__rule('allow_bootp') }
          it { is_expected.to create_logrotate__rule('dhcpd') }
          it { is_expected.to contain_rsyslog__rule__local ( 'XX_dhcpd' ) }
        end
      end
    end
  end
end

