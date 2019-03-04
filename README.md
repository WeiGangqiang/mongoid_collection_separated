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
  separated_by :form_id, :calc_collection_name
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/mongoid_collection_separatable.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
