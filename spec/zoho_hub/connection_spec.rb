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
    let(:authorization_header) do
      described_class.new(access_token: -> { '123' }).send(:authorization)
    end

    it 'returns zoho oauthtoken header value' do
      expect(authorization_header).to eq('Zoho-oauthtoken 123')
    end
  end

  describe '#with_refresh' do
    let(:access_token) do
      {
        access_token: '123',
        api_domain: 'https://www.zohoapis.com',
        token_type: 'Bearer',
        expires_in: 3600,
        refresh_token: "xxx"
      }
    end

    let(:invalid_http_response) do
      {
        code: 'INVALID_TOKEN',
        details: {},
        message: 'invalid oauth token',
        status: 'error'
      }
    end

    before { allow(ZohoHub::Auth).to receive(:refresh_token).and_return(access_token) }

    context 'when request returns invalid token' do
      let(:subject) { described_class.new(access_token: 'foo', refresh_token: 'xxx') }

      it 'sets the access_token value' do
        expect(subject.access_token).to eq('foo')
        expect do
          subject.send(:with_refresh) { double(body: invalid_http_response) }
        end.to change(subject, :access_token).to eq('123')
      end

      context 'with access_token as lambda' do
        let(:subject) { described_class.new(access_token: -> { 'bar' }, refresh_token: 'xxx') }

        it 'does not change the access_token value' do
          expect(subject.access_token).to eq('bar')
          expect do
            subject.send(:with_refresh) { double(body: invalid_http_response) }
          end.not_to change(subject, :access_token)
          expect(subject.access_token).to eq('bar')
        end
      end
    end
  end
end
