describe 'dhcp' do

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      let(:facts) do
        facts
      end

      context "on #{os}" do
        it { should compile.with_all_deps }
        it { should contain_class('dhcp::dhcpd') }
      end
    end
  end
end

