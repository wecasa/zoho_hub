# frozen_string_literal: true

RSpec.describe ZohoHub do
  it 'has a version number' do
    expect(ZohoHub::VERSION).not_to be nil
  end

  describe '#on_initialize_connection' do
    it 'calls the proc once' do
      init_connection = spy
      described_class.on_initialize_connection do
        init_connection.call
      end
      described_class.connection.instance_variable_set(:@adapter, nil)
      described_class.connection.send(:adapter)
      expect(init_connection).to have_received(:call)
    end
  end
end
