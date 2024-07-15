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

  describe '#access_token' do
    it 'returns access_token string value' do
      expect(described_class.new(access_token: '123').access_token).to eq('123')
    end

    it 'returns value from proc call' do
      expect(described_class.new(access_token: -> { '123' }).access_token).to eq('123')
    end
  end

  describe '#authorization' do
    let(:authorization_header) { described_class.new(access_token: -> { '123' }).send(:authorization) }

    it 'returns zoho oauthtoken header value' do
      expect(authorization_header).to eq('Zoho-oauthtoken 123')
    end
  end
end
