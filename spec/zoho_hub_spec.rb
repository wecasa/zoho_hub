# frozen_string_literal: true

RSpec.describe ZohoHub do
  it 'has a version number' do
    expect(ZohoHub::VERSION).not_to be nil
  end

  describe '#on_initialize_connection' do
    let(:initialize_connection) { spy('initialize_connection') }

    it 'calls the proc once' do
      described_class.on_initialize_connection do
        initialize_connection.call
      end
      described_class.connection.send(:adapter)
      expect(initialize_connection).to have_received(:call)
    end
  end
end
