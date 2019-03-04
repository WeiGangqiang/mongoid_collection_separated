require_relative 'form'
require_relative 'form_spilt'

class Entry
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::CollectionSeparated
  include Mongoid::Attributes::Dynamic

  index({ form_id: 1 }, { background: true })

  field :name, type: String

  belongs_to :form
  embeds_one :metainfo

  separated_by :form_id, :calc_collection_name, parent_class: 'Form'

  class << self
    def calc_collection_name form_id
      return if form_id.nil?
      return if FormSpilt.find_by(form_id: form_id).nil?
      "entries_#{form_id}"
    end
  end

end

