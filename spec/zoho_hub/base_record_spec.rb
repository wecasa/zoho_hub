# frozen_string_literal: true

RSpec.describe ZohoHub::BaseRecord do
  let(:test_class) do
    Class.new(described_class) do
      attributes :my_string, :my_bool, :id

      attribute_translation id: :id
    end
  end

  let(:id) { generate(:zoho_id) }

  before { allow(test_class).to receive(:request_path).and_return('Leads') }

  describe '.find' do
    context 'with an existing record' do
      let!(:stub_get_request) do
        stub_request(:get, "https://crmsandbox.zoho.eu/crm/v2/Leads/#{id}")
          .to_return(status: 200, body: { data: [{ id: id }] }.to_json)
      end

      it 'gets the record' do
        record = test_class.find(id)
        expect(stub_get_request).to have_been_requested
        expect(record.id).to eq id
      end
    end

    context 'with a not found record' do
      let!(:stub_get_request) do
        stub_request(:get, "https://crmsandbox.zoho.eu/crm/v2/Leads/#{id}")
          .to_return(status: 404, body: { status: 'error', code: 'RESOURCE_NOT_FOUND' }.to_json)
      end

      it 'raises a record not found error' do
        expect do
          test_class.find(id)
        end.to raise_error(ZohoHub::RecordNotFound)
        expect(stub_get_request).to have_been_requested
      end
    end

    context 'with a unknown record' do
      let!(:stub_get_request) do
        stub_request(:get, "https://crmsandbox.zoho.eu/crm/v2/Leads/#{id}")
          .to_return(status: 404, body: { status: 'error', code: 'FOOBAR' }.to_json)
      end

      it 'raises a record not found error' do
        expect do
          test_class.find(id)
        end.to raise_error(ZohoHub::UnknownError)
        expect(stub_get_request).to have_been_requested
      end
    end
  end

  describe '.where' do
    context 'with built-in criteria' do
      let(:email) { 'test@example.com' }

      let!(:stub_search_request) do
        stub_request(:get, "https://crmsandbox.zoho.eu/crm/v2/Leads/search?email=#{email}")
          .to_return(status: 200, body: { data: [{ id: generate(:zoho_id) }] }.to_json)
      end

      it 'gets the records' do
        records = test_class.where(email: email)
        expect(records).to be_a Array
        expect(records.size).to eq 1
        expect(stub_search_request).to have_been_requested
      end
    end

    context 'with custom criteria' do
      let!(:stub_search_request) do
        stub_request(:get, 'https://crmsandbox.zoho.eu/crm/v2/Leads/search?criteria=My_String:equals:foo')
          .to_return(status: 200, body: { data: [{ id: generate(:zoho_id) }] }.to_json)
      end

      it 'gets the records' do
        records = test_class.where(my_string: 'foo')
        expect(records).to be_a Array
        expect(records.size).to eq 1
        expect(stub_search_request).to have_been_requested
      end
    end
  end

  describe '.delete_all' do
    let!(:stub_delete_request) do
      stub_request(:delete, 'https://crmsandbox.zoho.eu/crm/v2/Leads?ids=1,2')
        .to_return(status: 200, body: '', headers: {})
    end

    it 'sends delete request delete for ids' do
      test_class.delete_all([1, 2])
      expect(stub_delete_request).to have_been_requested
    end
  end

  describe '.find_all' do
    let(:data) { [{ My_String: 'a', id: '1' }, { My_String: 'b', id: '2' }] }
    let(:body) { { data: data } }

    let!(:stub_find_all_request) do
      stub_request(:get, 'https://crmsandbox.zoho.eu/crm/v2/Leads?ids=1,2')
        .to_return(status: 200, body: body.to_json)
    end

    it 'fetches several records' do
      records = test_class.find_all(data.map { |r| r[:id] })
      expect(records).to be_a Array
      expect(records.size).to eq data.size
      expect(records.map(&:my_string)).to eq %w[a b]
      expect(stub_find_all_request).to have_been_requested
    end
  end

  describe '#build_response' do
    context 'with an empty string and a "false" boolean' do
      let(:body) { { data: [{ My_String: '', My_Bool: false }] } }

      it 'correctly build the record' do
        response = test_class.build_response(body)
        record = test_class.new(response.data.first)

        expect(record.my_string).to eq('')
        expect(record.my_bool).to eq(false)
      end
    end
  end

  describe '#blueprint_transition' do
    let(:test_instance) { test_class.new(id: id) }
    let!(:get_transition_id_stub) do
      stub_request(
        :get, "https://crmsandbox.zoho.eu/crm/v2/Leads/#{test_instance.id}/actions/blueprint"
      ).to_return(status: 200,
                  body: { blueprint: { transitions: [{ next_field_value: 'Closed',
                                                       id: 'transition-123' }] } }.to_json)
    end
    let!(:update_status_with_transition_stub) do
      stub_request(
        :put, "https://crmsandbox.zoho.eu/crm/v2/Leads/#{test_instance.id}/actions/blueprint"
      ).with(body: { blueprint: [{ transition_id: 'transition-123', data: {} }] })
        .to_return(status: 200, body: {}.to_json)
    end

    it 'gets the transition id and performs the transtion' do
      test_instance.blueprint_transition('Closed')
      expect(get_transition_id_stub).to have_been_requested
      expect(update_status_with_transition_stub).to have_been_requested
    end
  end

  describe '#notes' do
    let(:test_instance) { test_class.new(id: id) }
    let(:data_notes) { { data: [{ Note_Title: 'Title', Note_Content: 'content' }] } }
    let!(:get_notes_stub) do
      stub_request(:get, "https://crmsandbox.zoho.eu/crm/v2/Leads/#{test_instance.id}/Notes")
        .to_return(status: 200,
                   body: data_notes.to_json)
    end

    it 'fetches notes from the record' do
      notes = test_instance.notes
      expect(notes.class).to eq Array
      expect(notes.first.class).to eq ZohoHub::Note
      expect(notes.first.content).to eq 'content'
      expect(get_notes_stub).to have_been_requested
    end

    context 'without any notes' do
      let(:data_notes) { '' }

      it 'returns empty array' do
        notes = test_instance.notes
        expect(notes.class).to eq Array
        expect(notes).to be_empty
        expect(get_notes_stub).to have_been_requested
      end
    end
  end

  describe '.add_notes' do
    let(:note_attributes) { { id: id, title: 'Title', content: 'Content' } }
    let!(:post_note_stub) do
      stub_request(:post, "https://crmsandbox.zoho.eu/crm/v2/Leads/#{id}/Notes")
        .to_return(status: 200, body: { data: [{ status: 'success', code: 'SUCCESS' }] }.to_json)
    end

    it 'creates a Note from the record' do
      test_class.add_note(**note_attributes)
      expect(post_note_stub).to have_been_requested
    end
  end
end
