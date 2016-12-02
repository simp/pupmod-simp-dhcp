require 'spec_helper'

describe 'dhcp::dhcpd' do

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end

      context "on #{os}" do
        context 'in the :foo environment' do
          let(:environment){:foo}

          it { is_expected.to create_class('dhcp::dhcpd') }
          it { is_expected.to compile.with_all_deps }

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

          it { is_expected.to create_iptables_rule('allow_bootp') }

          it { is_expected.to contain_package('dhcp').with_ensure('latest') }

          it { is_expected.to contain_service('dhcpd').with({
              :ensure  =>'running',
              :require => ['File[/etc/dhcpd.conf]', 'Package[dhcp]']
            })
          }

          it { is_expected.to contain_rsyslog__rule__local ( 'XX_dhcpd' ) }
        end
      end
    end
  end
end

