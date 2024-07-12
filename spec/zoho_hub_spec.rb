# frozen_string_literal: true

RSpec.describe ZohoHub do
  it 'has a version number' do
    expect(ZohoHub::VERSION).not_to be nil
  end

  describe '#on_initialize_connection' do
    let(:proc) { double('Proc', call: true) }

    it "calls the proc once" do
      expect do |block|
        ZohoHub.on_initialize_connection(&block)
        ZohoHub.connection.send(:adapter)
      end.to yield_control
    end
  end
end
