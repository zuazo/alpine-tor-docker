require_relative '../spec_helper'

describe 'Dockerfile build' do
  it 'creates image' do
    expect(image).not_to be_nil
  end

  it 'runs proxychains wrapper in foreground' do
    expect(image_config['Entrypoint']).to include '/usr/bin/proxychains_wrapper'
  end

  it 'runs a shell by default' do
    expect(image_config['Cmd']).to include '/bin/sh'
  end

  context 'on environment' do
    let(:env_keys) { image_config['Env'].map { |x| x.split('=', 2)[0] } }

    it 'sets Tor log dir' do
      expect(env_keys).to include('TOR_LOG_DIR')
    end
  end
end
