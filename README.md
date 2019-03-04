# MongoidCollectionSeparatable

Support mongoid collections to be saved into and queried from separated collections with condition

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mongoid_collection_separated'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongoid_collection_separated

## Usage
Add the following line into the model class that you want to split:
### 1. spepated by simple field
```ruby
    class Entry
      include Mongoid::Document
      include Mongoid::Timestamps
      include Mongoid::CollectionSeparated
      include Mongoid::Attributes::Dynamic

      separated_by :collection_suffix, :calc_collection_name
      class << self
        def calc_collection_name collection_suffix
          return if collection_suffix.nil?
          "entries_#{collection_suffix}"
        end
      end
    end
```

### 2. spepated by belongs to model id
```ruby
    class Entry
      include Mongoid::Document
      include Mongoid::Timestamps
      include Mongoid::CollectionSeparated
      include Mongoid::Attributes::Dynamic
      belongs_to :form

      separated_by :form_id, :calc_collection_name, parent_class: 'Form'
      class << self
        def calc_collection_name form_id
          return if form_id.nil?
          "entries_#{form_id}"
        end
      end
    end


    class Form
      include Mongoid::Document
      has_many :entries
    end

```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/WeiGangqiang/mongoid_collection_separated

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
