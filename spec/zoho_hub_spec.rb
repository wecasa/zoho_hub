# frozen_string_literal: true

RSpec.describe ZohoHub do
  it 'has a version number' do
    expect(ZohoHub::VERSION).not_to be nil
  end

  describe '#on_initialize_connection' do
    let(:initialize_connection) { double('initialize_connection', call: true) }

    it 'calls the proc once' do
      described_class.on_initialize_connection do
        initialize_connection.call
      end
      expect(initialize_connection).to receive(:call)
      described_class.connection.send(:adapter)
    end
  end
end
