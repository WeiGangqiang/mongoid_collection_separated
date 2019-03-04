class Metainfo
  include Mongoid::Document
  embedded_in :entry

  field :device, type: String
end