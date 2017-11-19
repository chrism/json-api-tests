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

## Testing a JSONAPI model

First lets see what a valid response looks like with a model

`bin/rails c`
`Schedule.create(name: 'Test')`

Then hitting the same URL should return the model in an array.

I like to use an application called [Paw](https://paw.cloud/) to investigate how an API works, it makes it very simple to test requests and their responses in easy to view formats.

In this instance the response follows the standard JSON API format with a top-level member of `data`, followed in this instance with an array of `schedule` models (in this case one).

```json
{
  "data": [
    {
      "id": "2",
      "type": "schedules",
      "links": {
        "self": "http://0.0.0.0:3000/api/v1/schedules/2"
      }
    }
  ]
}
```

This includes the minimum compliant information. Every JSON API object [must have] an `id` and `type`(http://jsonapi.org/format/#document-resource-objects). The `self` link is good practice as a reference to get the URL of that specific model and is included by default, too.

To get additional data attributes are used by JSONAPI:Resources, which match the approach of the spec.

Adding to the Schedule resource

app/resources/api/v1/schedule_resource.rb
```ruby
class Api::V1::ScheduleResource < JSONAPI::Resource
  attributes :name, :current_position
end
```

Results now in a response with those attributes included

```json
{
  "data": [
    {
      "id": "2",
      "type": "schedules",
      "links": {
        "self": "http://0.0.0.0:3000/api/v1/schedules/2"
      },
      "attributes": {
        "name": "Test",
        "current-position": 0
      }
    }
  ]
}
```

Automated tests to check the responses are correct can be very useful.

RSpec includes [request specs](https://relishapp.com/rspec/rspec-rails/docs/request-specs/request-spec) to help with this.

Generate a request spec for schedules with

`bin/rails g rspec:request schedules`

There is another gem called [JSON RSpec](https://github.com/collectiveidea/json_spec) which provides some useful RSpec matchers (among other things).

Gemfile
```ruby
group :development, :test do
  ...
  gem 'json_spec', '~> 1.1', '>= 1.1.5'
end
```

spec/requests/schedules_spec.rb
```ruby
require 'rails_helper'

RSpec.describe "Schedules", type: :request do
  describe "GET /api/v1/schedules" do
    it "has correct status and content type" do
      get "/api/v1/schedules"
      expect(response).to have_http_status(200)
      expect(response.content_type).to eq("application/vnd.api+json")
    end

    it "has empty body array by default" do
      get "/api/v1/schedules"
      json = response.body
      expect(json).to have_json_path("data")
      expect(json).to have_json_size(0).at_path("data")
    end

    it "includes a schedule model when added" do
      Schedule.create(name: "Test")
      get "/api/v1/schedules"
      json = response.body
      expect(json).to have_json_path("data")
      expect(json).to have_json_size(1).at_path("data")
      expect(json).to have_json_path("data/0/id")
      attributes = %({
        "name": "Test",
        "current-position": 0
      })
      expect(response.body).to be_json_eql(attributes).at_path("data/0/attributes")
    end

    it "includes two schedule models when added" do
      Schedule.create(name: "Test")
      Schedule.create(name: "Test 2")
      get "/api/v1/schedules"
      json = response.body
      expect(json).to have_json_path("data")
      expect(json).to have_json_size(2).at_path("data")
      expect(json).to have_json_path("data/1/id")
      attributes = %({
        "name": "Test 2",
        "current-position": 0
      })
      expect(json).to be_json_eql(attributes).at_path("data/1/attributes")
    end
  end
end
```

These specs use some of those matchers to ensure that the JSON returned from the requests is correct.

## Adding slugs to a Model

Using the [Friendly ID](https://github.com/norman/friendly_id/) gem to generate slugs instead of IDs.

Gemfile
```ruby
gem 'friendly_id', '~> 5.1'
```

Then follow the guide by installing the configuration file

`rails generate friendly_id`

And running the migration

`rails db:migrate`

(May need to add the version number to migration file [see the note](https://github.com/norman/friendly_id/#usage) in the install instructions)

Now, using the gem to update the model to use a slug from the name.

app/models/schedule.rb
```ruby
class Schedule < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
end
```

There needs to be a slug column in the Schedules table too.

`rails g migration AddSlugToSchedules slug:string:uniq`

Then run the migration.

`bin/rails db:migrate`

## Using Slug for an id

These slugs can be used as the id of the JSONAPI models now, instead of the id integer.

Here is a test in the schedules request spec to test for the use of the slug as the id.

spec/requests/schedules_spec.rb
```ruby
describe "GET /api/v1/schedules/id" do
  it "should use the slug as the id" do
    Schedule.create(name: "Test With Spaces")
    get "/api/v1/schedules/test-with-spaces"
    expect(response).to have_http_status(200)
    expect(response.content_type).to eq("application/vnd.api+json")
    expect(response.body).to have_json_path("data")
    expect(response.body).to be_json_eql(%("test-with-spaces")).at_path("data/id")
  end
end
```

To make this test pass, the schedules resource must use the slug as the `primary_key` as [documented](http://jsonapi-resources.com/v0.10/guide/resources.html#Primary-Key).

app/resources/api/v1/schedule_resource.rb
```ruby
class Api::V1::ScheduleResource < JSONAPI::Resource
  primary_key :slug
  key_type :string
  attributes :name, :current_position
end
```
