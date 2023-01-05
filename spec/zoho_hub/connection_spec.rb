# frozen_string_literal: true

require 'zoho_hub/connection'

RSpec.describe ZohoHub::Connection do
  context 'when initializing a new Connection' do
    describe '@api_domain' do
      it 'corresponds to config api_domain - US' do
        ZohoHub.configuration.api_domain = 'https://accounts.zoho.com'
        result = described_class.new(access_token: '').api_domain

        expect(result).to eq('https://www.zohoapis.com')
      end

      it 'corresponds to config api_domain - CN' do
        ZohoHub.configuration.api_domain = 'https://accounts.zoho.com.cn'
        result = described_class.new(access_token: '').api_domain

        expect(result).to eq('https://www.zohoapis.com.cn')
      end

      it 'corresponds to config api_domain - IN' do
        ZohoHub.configuration.api_domain = 'https://accounts.zoho.in'
        result = described_class.new(access_token: '').api_domain

        expect(result).to eq('https://www.zohoapis.in')
      end

      it 'corresponds to config api_domain - EU' do
        ZohoHub.configuration.api_domain = 'https://accounts.zoho.eu'
        result = described_class.new(access_token: '').api_domain

        expect(result).to eq('https://www.zohoapis.eu')
      end

      it 'defaults if config api_domain is nil' do
        ZohoHub.configuration.api_domain = nil
        result = described_class.new(access_token: '').api_domain

        expect(result).to eq(described_class::DEFAULT_DOMAIN)
      end

      it 'defaults if config api_domain is empty' do
        ZohoHub.configuration.api_domain = ''
        result = described_class.new(access_token: '').api_domain

        expect(result).to eq(described_class::DEFAULT_DOMAIN)
      end

      it 'allows overriding via argument' do
        ZohoHub.configuration.api_domain = 'https://accounts.zoho.eu'
        connection = described_class.new(access_token: '',
                                         api_domain: 'custom domain')
        result = connection.api_domain

        expect(result).to eq('custom domain')
      end
    end
  end

  describe '#with_refresh' do
    subject(:connection) do
      described_class.new(
        access_token: 'TOKEN_1', expires_in: 'EXPIRES_IN_SEC', refresh_token: 'REFRESH_TOKEN',
        api_domain: ZohoHub.configuration.api_domain
      )
    end

    before do
      allow(ZohoHub).to receive(:configuration).and_return(ZohoHub::Configuration.new)
    end

    let!(:get_stub) do
      stub_request(:get, ZohoHub.configuration.api_domain)
        .to_return([
                     { status: 400, body: { code: 'INVALID_TOKEN', status: 'error' }.to_json },
                     { status: 200, body: '' }
                   ])
    end

    let!(:token_refresh_stub) do
      stub_request(:post, "#{connection.api_domain}/oauth/v2/token?client_id=" \
                          '&client_secret=&grant_type=refresh_token&refresh_token=REFRESH_TOKEN')
        .and_return(body: { access_token: 'TOKEN_2' }.to_json)
    end

    it 'refreshes access token if invalid' do
      expect do
        connection.get('/')
      end.to change(connection, :access_token).from('TOKEN_1').to('TOKEN_2')
      expect(get_stub).to have_been_requested.twice
      expect(token_refresh_stub).to have_been_requested
    end
  end
end
