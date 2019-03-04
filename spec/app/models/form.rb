class Form
  include Mongoid::Document
  has_many :entries

  def entries_separate
      FormSpilt.create(form_id: self.id)
  end
end
