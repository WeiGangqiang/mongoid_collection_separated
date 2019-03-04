lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mongoid/collection_separated/version"

Gem::Specification.new do |spec|
  spec.name          = "mongoid-collection-separated"
  spec.version       = Mongoid::CollectionSeparated::VERSION
  spec.authors       = ["aibotyu"]
  spec.email         = ["284894567@qq.com"]

  spec.summary       = %q{Save the mongoid model into different collections by condition}
  spec.description   = %q{Mongoid models are saved in one collection by default. However, when collections after too large , it could be extracted into a separated one and query form that, to make it query faster}
  spec.homepage      = "https://github.com/WeiGangqiang/mongoid_collection_separated"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency 'mongoid', ' ~> 6.4.0'

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry-byebug", "~> 3.4"

end
