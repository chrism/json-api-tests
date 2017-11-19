# Testing JSONAPI

## Introduction

This is a reference repo to aid with the comprehension of working with JSONAPI and the JSONAPI:Resources gem.

## Stack

- Rails 5.1.3 (postgres and API)
- RSpec

## Setup

### Install Rails project

`rails new json-api-tests --api --database=postgresql`

### Install RSpec & spring commands (for binstubs)

Gemfile
```ruby
group :development, :test do
  gem 'rspec-rails', '~> 3.7', '>= 3.7.1'
end

group :development do
  gem 'spring-commands-rspec', '~> 1.0', '>= 1.0.4'
end
```

`bundle`
`bin/rails generate rspec:install`
`bundle exec spring binstub rspec`

Customise RSpec a little

.rspec
```ruby
--require spec_helper
--format documentation
```

config/application.rb
```ruby
module JsonApiTests
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.generators do |g|
      g.test_framework :rspec,
        fixtures: false,
        view_specs: false,
        helper_specs: false,
        routing_specs: false
    end
    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end
```

Finally delete the redundant `test` directory.

### Setup Databases

`bin/rails db:create:all`

## Testing Models

Generated model using generators

`rails g model schedule name current_position:integer`

Add default value into Migration

```ruby
class CreateSchedules < ActiveRecord::Migration[5.1]
  def change
    create_table :schedules do |t|
      t.string :name
      t.integer :current_position, default: 0

      t.timestamps
    end
  end
end
```

Then need to make sure database is prepared with

`bin/rails db:test:prepare`

Now Rspec tests should pass like

spec/models/schedule_spec.rb
```ruby
require 'rails_helper'

RSpec.describe Schedule, type: :model do
  it "is valid with a name" do
    schedule = Schedule.new(
      name: "Orange Gardens Radio"
    )
    expect(schedule).to be_valid
  end

  it "has a current_position of 0" do
    schedule = Schedule.new(
      name: "Orange Gardens Radio"
    )
    expect(schedule.current_position).to be_zero
  end
end
```

## Creating a JSONAPI

Using [JSONAPI::Resources](http://jsonapi-resources.com/)

Install latest version with

Gemfile
```ruby
# Latest alpha from master on 14th November 2017
gem 'jsonapi-resources', :git => 'https://github.com/cerebris/jsonapi-resources.git', :ref => '3a02a4d'
```

`bundle`

Then we create a Resource and Controller as per the guides.

It is good practice to namespace the API, which you can do when using the generators.

`rails g jsonapi:controller api/v1/schedule`
`rails g jsonapi:resource api/v1/schedule`

The resource also needs to be added to the routes.

config/routes.rb
```ruby
Rails.application.routes.draw do

  namespace :api do
    namespace :v1 do
      jsonapi_resources :schedules
    end
  end

end
```

Tests should still pass when running

`bin/rspec`

And hitting the URL should now return a valid JSONAPI response (the [JSON API](http://jsonapi.org/) spec requires request to [include the `Content-type: application/vnd.api+json` in the header](http://jsonapi.org/format/#content-negotiation-clients)).

`curl "http://0.0.0.0:3000/api/v1/schedules" -H 'Content-Type: application/vnd.api+json'`
