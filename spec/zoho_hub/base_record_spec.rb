# frozen_string_literal: true

RSpec.describe ZohoHub::BaseRecord do
  let(:test_class) do
    Class.new(described_class) do
      attributes :my_string, :my_bool, :id
    end
  end

  describe '.delete_all' do
    before { allow(test_class).to receive(:request_path).and_return('Leads') }

    let!(:stub_delete_request) do
      stub_request(:delete, 'https://crmsandbox.zoho.eu/crm/v2/Leads?ids=1,2')
        .to_return(status: 200, body: '', headers: { "Content-Type": 'application/json' })
    end

    it 'sends delete request delete for ids' do
      test_class.delete_all([1, 2])
      expect(stub_delete_request).to have_been_requested
    end
  end

  describe '.find_all' do
    before { allow(test_class).to receive(:request_path).and_return('Leads') }

    let(:data) { [{ My_String: 'a', id: '1' }, { My_String: 'b', id: '2' }] }
    let(:body) { { data: data } }

    let!(:stub_find_all_request) do
      stub_request(:get, 'https://crmsandbox.zoho.eu/crm/v2/Leads?ids=1,2')
        .to_return(status: 200, body: body.to_json, headers: { "Content-Type": 'application/json' })
    end

    it 'fetches several records' do
      records = test_class.find_all(data.map { |r| r[:id] })
      expect(records).to be_a Array
      expect(records.size).to eq data.size
      expect(records.map(&:my_string)).to eq %w[a b]
      expect(stub_find_all_request).to have_been_requested
    end
  end

  describe '.associate_tags' do
    before { allow(test_class).to receive(:request_path).and_return('Leads') }

    let!(:stub_add_tags_request) do
      stub_request(:post, 'https://crmsandbox.zoho.eu/crm/v2/Leads/actions/add_tags?tag_names=tag1,tag2&ids=1,2')
        .to_return(status: 200, body: '', headers: { "Content-Type": 'application/json' })
    end

    it 'associate tags to records' do
      test_class.associate_tags([1, 2], %w[tag1 tag2])
      expect(stub_add_tags_request).to have_been_requested
    end

    context 'when the request is too big' do
      let!(:stub_add_tags_request_first_batch) do
        stub_request(:post, "https://crmsandbox.zoho.eu/crm/v2/Leads/actions/add_tags?tag_names=tag1,tag2&ids=#{(1..100).to_a.join(',')}")
          .to_return(status: 200, body: '', headers: { "Content-Type": 'application/json' })
      end
      let!(:stub_add_tags_request_second_batch) do
        stub_request(:post, "https://crmsandbox.zoho.eu/crm/v2/Leads/actions/add_tags?tag_names=tag1,tag2&ids=#{(101..200).to_a.join(',')}")
          .to_return(status: 200, body: '', headers: { "Content-Type": 'application/json' })
      end

      it 'splits the request in batches' do
        test_class.associate_tags((1..200).to_a, %w[tag1 tag2])
        expect(stub_add_tags_request_first_batch).to have_been_requested
        expect(stub_add_tags_request_second_batch).to have_been_requested
      end
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
    let(:test_instance) { test_class.new(id: '123456789') }
    let!(:get_transition_id_stub) do
      body = {
        blueprint: {
          transitions: [
            { next_field_value: 'Closed', id: 'transition-123' }
          ]
        }
      }
      stub_request(:get, "https://crmsandbox.zoho.eu/crm/v2/Leads/#{test_instance.id}/actions/blueprint")
        .to_return(status: 200, body: body.to_json, headers: { "Content-Type": 'application/json' })
    end
    let!(:update_status_with_transition_stub) do
      stub_request(:put, "https://crmsandbox.zoho.eu/crm/v2/Leads/#{test_instance.id}/actions/blueprint")
        .with(body: { blueprint: [{ transition_id: 'transition-123', data: {} }] })
        .to_return(status: 200, body: {}.to_json, headers: { "Content-Type": 'application/json' })
    end

    before { allow(test_class).to receive(:request_path).and_return('Leads') }

    it 'gets the transition id and performs the transtion' do
      test_instance.blueprint_transition('Closed')
      expect(get_transition_id_stub).to have_been_requested
      expect(update_status_with_transition_stub).to have_been_requested
    end
  end

  describe '#associate_tags' do
    let(:test_instance) { test_class.new(id: '123456789') }
    let(:tag_names) { %w[tag1 tag2] }
    let!(:associate_tags_stub) do
      stub_request(:post, "https://crmsandbox.zoho.eu/crm/v2/Leads/#{test_instance.id}/actions/add_tags?tag_names=tag1,tag2")
        .to_return(status: 200, body: {}.to_json, headers: { "Content-Type": 'application/json' })
    end

    before { allow(test_class).to receive(:request_path).and_return('Leads') }

    it 'associates tags to the record' do
      test_instance.associate_tags(tag_names)
      expect(associate_tags_stub).to have_been_requested
    end
  end

  describe '#notes' do
    let(:test_instance) { test_class.new(id: '123456789') }
    let(:data_notes) { { data: [{ Note_Title: 'Title', Note_Content: 'content' }] } }
    let!(:get_notes_stub) do
      stub_request(:get, "https://crmsandbox.zoho.eu/crm/v2/Leads/#{test_instance.id}/Notes")
        .to_return(status: 200,
                   body: data_notes.to_json,
                   headers: { "Content-Type": 'application/json' })
    end

    before { allow(test_class).to receive(:request_path).and_return('Leads') }

    it 'fetches notes from the record' do
      notes = test_instance.notes
      expect(notes.class).to eq Array
      expect(notes.first.class).to eq ZohoHub::Note
      expect(notes.first.content).to eq 'content'
      expect(get_notes_stub).to have_been_requested
    end

    context 'without any notes' do
      let(:data_notes) { {} }

      it 'returns empty array' do
        notes = test_instance.notes
        expect(notes.class).to eq Array
        expect(notes).to be_empty
        expect(get_notes_stub).to have_been_requested
      end
    end
  end
end
