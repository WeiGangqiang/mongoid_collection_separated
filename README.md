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
```ruby
    class Entry
      include Mongoid::Document
      include Mongoid::Timestamps
      include Mongoid::CollectionSeparated
      include Mongoid::Attributes::Dynamic
      belongs_to :form

      separated_by :form_id, :calc_collection_name
      class << self
        def calc_collection_name form_id
          return if form_id.nil?
          "entries_#{form_id}"
        end
      end
    end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/WeiGangqiang/mongoid_collection_separated

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
