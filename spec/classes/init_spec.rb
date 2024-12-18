require 'spec_helper'

describe 'dhcp' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      let(:facts) { os_facts }

      context "on #{os}" do
        context 'in the foo environment' do
          let(:environment) { 'foo' }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_class('dhcp::dhcpd') }
        end
      end
    end
  end
end
