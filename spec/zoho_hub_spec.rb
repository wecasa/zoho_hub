# frozen_string_literal: true

RSpec.describe ZohoHub do
  it 'has a version number' do
    expect(ZohoHub::VERSION).not_to be nil
  end

  describe '#on_initialize_connection' do
    it 'calls the proc once' do
      proc = spy()
      described_class.on_initialize_connection do
        proc.call
      end
      described_class.connection.send(:adapter)
      expect(proc).to have_received(:call)
    end
  end
end
