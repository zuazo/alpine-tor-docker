require_relative '../serverspec_helper'

describe 'Docker image run' do
  tor_conf_file = '/etc/tor/torrc'
  proxychains_conf_file = '/etc/proxychains/proxychains.conf'
  dnsmasq_conf_file = '/etc/dnsmasq.conf'

  describe 'OpenSSL' do
    describe package('openssl') do
      it { should be_installed }
    end

    it 'has openssl in the path' do
      expect(command('which openssl').exit_status).to eq 0
    end
  end

  describe 'Tor' do
    describe package('tor') do
      it { should be_installed }
    end

    it 'has tor in the path' do
      expect(command('which tor').exit_status).to eq 0
    end

    # Requires a space to differentiate it from the "wrapper_proxichains" and
    # "s6 tor" processes.
    describe process('tor ') do
      it { should be_running }
      its(:user) { should eq 'tor' }
      its(:args) { should include "--defaults-torrc #{tor_conf_file}" }
    end

    describe port(9053) do
      it { should be_listening.with('udp') }
    end

    describe file(tor_conf_file) do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'tor' }
      its(:content) { should match(/^SocksPort +9050/) }
      its(:content) { should match %r{^DataDirectory +/var/lib/tor} }
      its(:content) { should match %r{^DNSPort +9053} }
    end
  end

  describe 'PorxyChains-NG' do
    describe package('proxychains-ng') do
      it { should be_installed }
    end

    it 'has proxychains in the path' do
      expect(command('which proxychains').exit_status).to eq 0
    end

    describe file(proxychains_conf_file) do
      it { should exist }
      it { should be_file }
      it { should be_mode 644 }
      its(:content) { should match(/^socks4\ +127\.0\.0\.1 +9050$/) }
    end
  end

  describe 'Dnsmasq' do
    describe package('dnsmasq') do
      it { should be_installed }
    end

    it 'has dnsmasq in the path' do
      expect(command('which dnsmasq').exit_status).to eq 0
    end

    describe process('dnsmasq') do
      it { should be_running }
    end

    describe port(53) do
      it { should be_listening.with('tcp') }
      it { should be_listening.with('udp') }
    end

    describe file(dnsmasq_conf_file) do
      it { should exist }
      it { should be_file }
      its(:content) { should match(/^no-resolv$/) }
      its(:content) { should match(/^server=127\.0\.0\.1#9053$/) }
      its(:content) { should match(/^user=root$/) }
      its(:content) { should match(/^interface=lo$/) }
      its(:content) { should match(/^bind-interfaces$/) }
    end
  end

  describe 'Scripts' do
    %w(tor_boot tor_wait proxychains_wrapper).each do |script|
      describe file("/usr/bin/#{script}") do
        it { should exist }
        it { should be_file }
        it { should be_executable }
        it { should be_mode 755 }
      end
    end
  end

  describe 'check.torproject.org' do
    let(:url) { 'https://check.torproject.org/' }
    let(:http_check_tor_cmd) { "proxychains_wrapper wget -O- #{url}" }

    it 'detects tor' do
      expect(command(http_check_tor_cmd).stdout)
        .to contain('Congratulations. This browser is configured to use Tor.')
    end
  end
end
