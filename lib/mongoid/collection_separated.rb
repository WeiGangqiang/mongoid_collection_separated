require 'mongoid'
require 'mongoid/collection_separated/monkey_patches'
require 'active_support'
require 'mongoid/collection_separated/version'


module Mongoid
  module CollectionSeparated
    extend ActiveSupport::Concern

    class_methods do
      attr_accessor :separated_field, :separated_parent_class, :separated_parent_field, :calc_collection_name_fun
      def separated_by separated_field, calc_collection_name_fun, opts={}
        @separated_parent_class = opts[:parent_class].constantize
        @separated_parent_field = opts[:parent_field] || :id
        @separated_field = separated_field
        @calc_collection_name_fun = calc_collection_name_fun
      end
    end

  end
end
