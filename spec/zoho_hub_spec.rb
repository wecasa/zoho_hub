# frozen_string_literal: true

RSpec.describe ZohoHub do
  it 'has a version number' do
    expect(ZohoHub::VERSION).not_to be nil
  end

  describe '#on_initialize_connection' do
    let(:initialize_connection) { -> { true } }

    it "calls the proc once" do
      ZohoHub.on_initialize_connection(&initialize_connection)
      expect(initialize_connection).to receive(:call)
      ZohoHub.connection.send(:adapter)
    end
  end
end
