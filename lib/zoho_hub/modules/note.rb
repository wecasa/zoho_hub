# frozen_string_literal: true

module ZohoHub
  class Note < BaseRecord
    attributes :id, :created_by, :modified_by, :owner, :parent_id, :created_time, :voice_note,
               :note_title, :note_content

    attribute_translation id: :id
    alias title note_title
    alias content note_content
  end
end
