class FormSpilt
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  has_one :Form
end