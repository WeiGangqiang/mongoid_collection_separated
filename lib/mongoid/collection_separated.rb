require 'mongoid'
require 'mongoid/collection_separated/monkey_patches'
require 'active_support'
require 'mongoid/collection_separated/version'


module Mongoid
  module CollectionSeparated
    extend ActiveSupport::Concern

    included do
      action_method_module = [Mongoid::Persistable.constants.map {|c| Mongoid::Persistable.const_get(c)} + [Mongoid::Reloadable]].flatten.select {|c| c.is_a?(Module)}
      action_method_module.each {|action_module| alias_method_with_collection action_module}
    end

    class_methods do
      attr_accessor :separated_field, :separated_parent_class, :separated_parent_field, :calc_collection_name_fun

      def separated_by separated_field, calc_collection_name_fun, opts={}
        @separated_parent_class = opts[:parent_class].constantize
        @separated_parent_field = opts[:parent_field] || :id
        @separated_field = separated_field
        @calc_collection_name_fun = calc_collection_name_fun
      end

      def alias_method_with_collection action_module
        action_module.instance_methods(false).each do |action_method|
          define_method "#{action_method}_with_context" do |*args|
            klass = self.class
            self.send "#{action_method}_without_context", *args unless klass.respond_to?(:separated_field)

            collection_name = klass.where(klass.separated_field => self.send(klass.separated_field)).ensured_collection.name
            self.with(collection: collection_name) {self.send "#{action_method}_without_context", *args}
          end

          alias_method "#{action_method}_without_context".to_sym, action_method
          alias_method action_method.to_sym, "#{action_method}_with_context".to_sym
        end
      end

    end

  end
end
