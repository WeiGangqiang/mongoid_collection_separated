
module Mongoid
  module SeparatedFun
    extend ActiveSupport::Concern

    included do
      def collection_name_for query_class, separated_key
        cache_key = "#{__method__}_#{separated_key}"
        return instance_variable_get "@#{cache_key}" if instance_variable_defined? "@#{cache_key}"
        collection_name = query_class.send(query_class.calc_collection_name_fun, separated_key)
        instance_variable_set "@#{cache_key}", collection_name
        collection_name
      end
    end

  end
end

module Mongoid
  module Contextual
    include Mongoid::SeparatedFun
    private

    # Changes:
    # 1. Get form_id from selector
    # 2. If collection is entries, not matter from context or current collection object, and form has entries_separated flag set, set collection  name instance variable to entries plus form_id as new collection name

    def create_context_with_separated
      context = create_context_without_separated
      query_class = instance_variable_get :@klass
      new_collection_name = calc_new_collection_name query_class
      unless new_collection_name.blank?
        context.collection.instance_variable_set :@name, new_collection_name
        collection.instance_variable_set :@name, new_collection_name
      end
      instance_variable_set :@context, context
      context
    end

    def calc_new_collection_name query_class
      return unless query_class.respond_to?(:separated_field) && query_class.send(:separated_field).present?
      return unless query_class.respond_to?(:calc_collection_name_fun) && query_class.respond_to?(query_class.calc_collection_name_fun)
      collection_name_for query_class, separated_value(query_class)
    end

    def separated_value query_class
      value = separated_selector(query_class)
      value = separated_value_from_query_in_with_only_one_value(query_class) if value.is_a?(Hash)
      value
    end

    def separated_value_from_query_in_with_only_one_value query_class
      separated_selector(query_class)['$in']&.first
    end

    def separated_selector query_class
      selector[query_class.separated_field.to_s]
    end

    alias_method :create_context_without_separated, :create_context
    alias_method :create_context, :create_context_with_separated
  end
end

module Mongoid
  module Relations
    module Referenced
      class Many < Relations::Many
        include Mongoid::SeparatedFun

        private

        # Changes:
        # 1. 'base' should be an instance of Form
        # 2. If form has entries_separated flat and collection name is entries, clone a new context because it is build each time when called and set to context. Then remove form_id from selector because all the entries inside the new collection has the same form_id

        def criteria_with_separated
          cri = criteria_without_separated
          query_class = cri.instance_variable_get :@klass
          if should_query_from_separated_collection? query_class
            context = cri.context.clone
            new_collection_name = calc_new_collection_name query_class
            unless new_collection_name.blank?
              context.collection.instance_variable_set :@name, new_collection_name
              cri.instance_variable_set :'@collection', @collection
            end
          end
          cri
        end

        def should_query_from_separated_collection?(query_class)
          is_separated_query_class?(query_class) && is_separated_parent_class?(query_class)
        end

        def is_separated_query_class? query_class
          query_class.respond_to?(:separated_field) && query_class.send(:separated_field) && query_class.respond_to?(:calc_collection_name_fun) && query_class.respond_to?(query_class.calc_collection_name_fun)
        end

        def is_separated_parent_class? query_class
          base.is_a?(query_class.separated_parent_class) && base.respond_to?(query_class.separated_parent_field)
        end

        def calc_new_collection_name query_class
          collection_name_for query_class, base.send(query_class.separated_parent_field)
        end

        alias_method :criteria_without_separated, :criteria
        alias_method :criteria, :criteria_with_separated
      end
    end
  end
end

module Mongoid
  # The +Criteria+ class is the core object needed in Mongoid to retrieve
  # objects from the database. It is a DSL that essentially sets up the
  # selector and options arguments that get passed on to a Mongo::Collection
  # in the Ruby driver. Each method on the +Criteria+ returns self to they
  # can be chained in order to create a readable criterion to be executed
  # against the database.
  class Criteria
    def ensured_collection
      context.collection
    end
  end
end

module Mongoid
  module Clients
    module Options
      def collection_with_separated(parent = nil)
        klass = self.class
        origin_collection = collection_without_separated(parent)
        return origin_collection unless self.class.respond_to?(:separated_field)
        origin_collection.instance_variable_set :@name, separated_collection_name(klass)
        origin_collection
      end

      alias_method :collection_without_separated, :collection
      alias_method :collection, :collection_with_separated

      def collection_name_with_separated
        klass = self.class
        origin_collection_name = collection_name_without_separated
        return origin_collection_name unless self.class.respond_to?(:separated_field)
        separated_collection_name klass
      end

      alias_method :collection_name_without_separated, :collection_name
      alias_method :collection_name, :collection_name_with_separated

      def separated_collection_name(klass)
        klass.where(klass.separated_field => self.send(klass.separated_field)).ensured_collection.name
      end
    end
  end
end

