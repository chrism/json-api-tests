# Test-driven JSONAPI development using Rails

## Contents

- [Introduction](https://github.com/chrism/json-api-tests#introduction)
- [Stack](https://github.com/chrism/json-api-tests#stack)
- [Setup](https://github.com/chrism/json-api-tests#setup)
- [Testing models](https://github.com/chrism/json-api-tests#testing-models)
- [Creating a JSONAPI response](https://github.com/chrism/json-api-tests#creating-a-jsonapi-response)
- [Testing a JSONAPI model](https://github.com/chrism/json-api-tests#testing-a-jsonapi-model)
- [Adding a slug to a model](https://github.com/chrism/json-api-tests#adding-a-slug-to-a-model)
- [Using a slug for an id](https://github.com/chrism/json-api-tests#using-a-slug-for-an-id)
- [Adding a has_many relationship](https://github.com/chrism/json-api-tests#adding-a-has_many-relationship)
- [Customising a has_many relationship](https://github.com/chrism/json-api-tests#customising-a-has_many-relationship)
- [Side-loading data using the include URL parameter](https://github.com/chrism/json-api-tests#side-loading-data-using-the-include-url-parameter)
- [A note about caching responses](https://github.com/chrism/json-api-tests#a-note-about-caching-responses)
- [Testing customized has_many relationships](https://github.com/chrism/json-api-tests#testing-customized-has_many-relationships)
- [Creating models and validation](https://github.com/chrism/json-api-tests#creating-models-and-validation)

## Introduction

This is a reference repo to aid with the comprehension of working with JSONAPI and the JSONAPI:Resources gem.

## Stack

- [Rails 5.1.3](http://rubyonrails.org/)
- [JSONAPI::Resources](http://jsonapi-resources.com/)
- [RSpec](https://relishapp.com/rspec)

## Setup

### Install Rails project

`⇒ rails new json-api-tests --api --database=postgresql`

### Install RSpec & spring commands (for binstubs)

**Gemfile**
```ruby
group :development, :test do
  gem 'rspec-rails', '~> 3.7', '>= 3.7.1'
end

group :development do
  gem 'spring-commands-rspec', '~> 1.0', '>= 1.0.4'
end
```

```
⇒ bundle
⇒ bin/rails generate rspec:install
⇒ bundle exec spring binstub rspec
```

Customise RSpec a little

**.rspec**
```
--require spec_helper
--format documentation
```

**config/application.rb**
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

`⇒ bin/rails db:create:all`

## Testing models

Generated model using generators

`⇒ rails g model schedule name current_position:integer`

Add default value into generated Migration file

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

`⇒ bin/rails db:test:prepare`

Now Rspec tests should pass like

**spec/models/schedule_spec.rb**
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

## Creating a JSONAPI response

Using [JSONAPI::Resources](http://jsonapi-resources.com/)

Install latest version with

**Gemfile**
```ruby
# Latest alpha from master on 14th November 2017
gem 'jsonapi-resources', :git => 'https://github.com/cerebris/jsonapi-resources.git', :ref => '3a02a4d'
```

`⇒ bundle`

Then we create a Resource and Controller as per the guides.

It is good practice to namespace the API, which you can do when using the generators.

```
⇒ rails g jsonapi:controller api/v1/schedule
⇒ rails g jsonapi:resource api/v1/schedule
```

The resource also needs to be added to the routes.

**config/routes.rb**
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

`⇒ bin/rspec`

And hitting the URL should now return a valid JSONAPI response (the [JSON API](http://jsonapi.org/) spec requires request to [include the `Content-type: application/vnd.api+json` in the header](http://jsonapi.org/format/#content-negotiation-clients)).

`curl "http://0.0.0.0:3000/api/v1/schedules" -H 'Content-Type: application/vnd.api+json'`

## Testing a JSONAPI model

First lets see what a valid response looks like with a model

```
⇒ bin/rails c
> Schedule.create(name: 'Test')
> exit
```

Now the same URL should return the model in an array.

[Paw](https://paw.cloud/) is a great 3rd party application to investigate how an API works. It makes it very simple to test requests and their responses in easy to view formats.

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

**app/resources/api/v1/schedule_resource.rb**
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

`⇒ bin/rails g rspec:request schedules`

There is another gem called [JSON RSpec](https://github.com/collectiveidea/json_spec) which provides some useful RSpec matchers (among other things).

**Gemfile**
```ruby
group :development, :test do
  ...
  gem 'json_spec', '~> 1.1', '>= 1.1.5'
end
```

**spec/requests/schedules_spec.rb**
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

## Adding a slug to a model

Using the [Friendly ID](https://github.com/norman/friendly_id/) gem to generate slugs instead of IDs.

**Gemfile**
```ruby
gem 'friendly_id', '~> 5.1'
```

Then follow the guide by installing the configuration file

`⇒ rails generate friendly_id`

And running the migration

`⇒ rails db:migrate`

(May need to add the version number to migration file [see the note](https://github.com/norman/friendly_id/#usage) in the install instructions)

Now, using the gem to update the model to use a slug from the name.

**app/models/schedule.rb**
```ruby
class Schedule < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged
end
```

There needs to be a slug column in the Schedules table too.

`⇒ rails g migration AddSlugToSchedules slug:string:uniq`

Then run the migration.

`⇒ bin/rails db:migrate`

## Using a slug for an id

These slugs can be used as the id of the JSONAPI models now, instead of the id integer.

Here is a test in the schedules request spec to test for the use of the slug as the id.

**spec/requests/schedules_spec.rb**
```ruby
describe "GET /api/v1/schedules/id" do
  it "should use the slug as the id" do
    Schedule.create(name: "Test With Spaces")
    get "/api/v1/schedules/test-with-spaces"
    expect(response).to have_http_status(200)
    expect(response.content_type).to eq("application/vnd.api+json")
    json = response.body
    expect(json).to have_json_path("data")
    expect(json).to be_json_eql(%("test-with-spaces")).at_path("data/id")
    expect(json).to be_json_eql(response.request.url.to_json).at_path("data/links/self")
  end
end
```

To make this test pass, the schedules resource must use the slug as the `primary_key` as [documented](http://jsonapi-resources.com/v0.10/guide/resources.html#Primary-Key).

**app/resources/api/v1/schedule_resource.rb**
```ruby
class Api::V1::ScheduleResource < JSONAPI::Resource
  primary_key :slug
  key_type :string
  attributes :name, :current_position
end
```

The model now uses the slug as the primary key.

## Adding a has many relationship

In this example a schedule can have many scheduled_tracks. Each scheduled_track belongs to a schedule.

`⇒ bin/rails g model scheduled_track position:integer state schedule:belongs_to`

The state should have a default value of `queued`, so this can be added to the migration before it is run.

```ruby
class CreateScheduledTracks < ActiveRecord::Migration[5.1]
  def change
    create_table :scheduled_tracks do |t|
      t.integer :position
      t.string :state, default: 'queued'
      t.belongs_to :schedule, foreign_key: true

      t.timestamps
    end
  end
end
```

Then add a JSONAPI resource and controller for `scheduled_tracks`

```
⇒ bin/rails g jsonapi:resource api/v1/scheduled_track
⇒ bin/rails g jsonapi:controller api/v1/scheduled_track
```

To include the has many relationship at it's most basic the relationship can be added to the `schedule` model.

**app/models/schedule.rb**
```ruby
class Schedule < ApplicationRecord
  #...
  has_many :scheduled_tracks
end
```

and the `schedule` resource

**app/resources/api/v1/schedule_resource.rb**
```ruby
class Api::V1::ScheduleResource < JSONAPI::Resource
  #...
  has_many :scheduled_tracks
end
```

By adding a couple of `schedule_track` models via the console to the development database these API relationships can be reviewed.

```
⇒ bin/rails c
> ScheduledTrack.create(position: 1, schedule: Schedule.first)
> ScheduledTrack.create(position: 2, schedule: Schedule.first)
> exit
```

Now, a request to the API for a schedule will include the schedule_tracks too.

`curl "http://0.0.0.0:3000/api/v1/schedules/test" -H 'Content-Type: application/vnd.api+json'`

```json
{
  "data": {
    "id": "test",
    "type": "schedules",
    "links": {
      "self": "http://0.0.0.0:3000/api/v1/schedules/test"
    },
    "attributes": {
      "name": "Test",
      "current-position": 0
    },
    "relationships": {
      "scheduled-tracks": {
        "links": {
          "self": "http://0.0.0.0:3000/api/v1/schedules/test/relationships/scheduled-tracks",
          "related": "http://0.0.0.0:3000/api/v1/schedules/test/scheduled-tracks"
        }
      }
    }
  }
}
```

By default there are only the links included in the response.

Following the `self` link works but the `related` link leads to an error.

This can be resolved by also including the `schedule_tracks` to the routes configuration.

**config/routes.rb**
```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      jsonapi_resources :schedules
      jsonapi_resources :scheduled_tracks
    end
  end
end
```

This now makes it possible to follow the links to a specific `schedule_track`

`curl "http://0.0.0.0:3000/api/v1/schedule-tracks/1" -H 'Content-Type: application/vnd.api+json'`

```json
{
  "data": {
    "id": "1",
    "type": "scheduled-tracks",
    "links": {
      "self": "http://0.0.0.0:3000/api/v1/scheduled-tracks/1"
    }
  }
}
```

As before the way to include additional information for the model is to add attributes to the resource.

**app/resources/api/v1/scheduled_track_resource.rb**
```ruby
class Api::V1::ScheduledTrackResource < JSONAPI::Resource
  attributes :position, :state
end
```

Now the response includes those attributes

```json
{
  "data": {
    "id": "1",
    "type": "scheduled-tracks",
    "links": {
      "self": "http://0.0.0.0:3000/api/v1/scheduled-tracks/1"
    },
    "attributes": {
      "position": 1,
      "state": "queued"
    }
  }
}
```

Writing some RSpec tests once again ensure the correct responses.

First some simple model specs

**spec/models/scheduled_track_spec.rb**
```ruby
require 'rails_helper'

RSpec.describe ScheduledTrack, type: :model do
  let!(:schedule) { Schedule.create(name: 'test') }

  it "is valid with a position" do
    scheduled_track = ScheduledTrack.new(
      position: 1,
      schedule: schedule
    )
    expect(scheduled_track).to be_valid
  end

  it "has a state of queued" do
    scheduled_track = ScheduledTrack.new(
      position: 1,
      schedule: schedule
    )
    expect(scheduled_track.state).to eq "queued"
  end
end
```

Then some additional specs to the request specs to ensure the `schedule` includes the links to the `scheduled_tracks`.

**spec/requests/schedules_spec.rb**
```ruby
it "includes the scheduled tracks links" do
  schedule = Schedule.create(name: "Test")
  ScheduledTrack.create(position: 1, schedule: schedule)
  ScheduledTrack.create(position: 2, schedule: schedule)
  get "/api/v1/schedules/test"
  json = response.body
  url_prepend = response.request.url
  expect(json).to have_json_path("data/relationships")
  expect(json).to be_json_eql(%("#{url_prepend}/relationships/scheduled-tracks")).at_path("data/relationships/scheduled-tracks/links/self")
  expect(json).to be_json_eql(%("#{url_prepend}/scheduled-tracks")).at_path("data/relationships/scheduled-tracks/links/related")
end
```

And create a scheduled_track request spec

`⇒ bin/rails g rspec:request scheduled_tracks`

**spec/requests/scheduled_tracks_spec.rb**
```ruby
require 'rails_helper'

RSpec.describe "ScheduledTracks", type: :request do
  describe "GET /scheduled-tracks/:id" do
    it "should return the position and default state" do
      schedule_track = ScheduledTrack.create(position: 1, schedule: Schedule.create(name: 'Test'))
      get "/api/v1/scheduled-tracks/#{schedule_track.id}"
      expect(response).to have_http_status(200)
      expect(response.content_type).to eq("application/vnd.api+json")
      attributes = %({
        "position": 1,
        "state": "queued"
      })
      expect(response.body).to be_json_eql(attributes).at_path("data/attributes")
    end
  end
end
```

## Customising a has_many relationship

To include the relationship side-loaded into the JSON response the JSONAPI convention is to include in the request an `include` parameter.

`curl "http://0.0.0.0:3000/api/v1/schedules/test?include=scheduled-tracks" -H 'Content-Type: application/vnd.api+json'`

Which returns a response including all of the related `scheduled_tracks`

```json
{
  "data": {
    "id": "test",
    "type": "schedules",
    "links": {
      "self": "http://0.0.0.0:3000/api/v1/schedules/test"
    },
    "attributes": {
      "name": "Test",
      "current-position": 0
    },
    "relationships": {
      "scheduled-tracks": {
        "links": {
          "self": "http://0.0.0.0:3000/api/v1/schedules/test/relationships/scheduled-tracks",
          "related": "http://0.0.0.0:3000/api/v1/schedules/test/scheduled-tracks"
        },
        "data": [
          {
            "type": "scheduled-tracks",
            "id": "1"
          },
          {
            "type": "scheduled-tracks",
            "id": "2"
          },
          {
            "type": "scheduled-tracks",
            "id": "3"
          },
          {
            "type": "scheduled-tracks",
            "id": "4"
          }
        ]
      }
    }
  },
  "included": [
    {
      "id": "1",
      "type": "scheduled-tracks",
      "links": {
        "self": "http://0.0.0.0:3000/api/v1/scheduled-tracks/1"
      },
      "attributes": {
        "position": 1,
        "state": "played"
      }
    },
    {
      "id": "2",
      "type": "scheduled-tracks",
      "links": {
        "self": "http://0.0.0.0:3000/api/v1/scheduled-tracks/2"
      },
      "attributes": {
        "position": 2,
        "state": "played"
      }
    },
    {
      "id": "3",
      "type": "scheduled-tracks",
      "links": {
        "self": "http://0.0.0.0:3000/api/v1/scheduled-tracks/3"
      },
      "attributes": {
        "position": 3,
        "state": "playing"
      }
    },
    {
      "id": "4",
      "type": "scheduled-tracks",
      "links": {
        "self": "http://0.0.0.0:3000/api/v1/scheduled-tracks/4"
      },
      "attributes": {
        "position": 4,
        "state": "queued"
      }
    }
  ]
}
```

This is very powerful, but sometimes you only want to include a specific result set in the response.

There are several ways of doing this, for example—to only show scheduled-tracks which have not been played first add a scope to the `Schedule` model

**app/models/schedule.rb**
```ruby
class Schedule < ApplicationRecord
  #...
  has_many :forthcoming_tracks, -> { where(state: ['playing','next','queued']) }, class_name: "ScheduledTrack"
end
```

Then update the resource to include this relationship

**app/resources/api/v1/schedule_resource.rb**
```ruby
class Api::V1::ScheduleResource < JSONAPI::Resource
  #...
  has_many "forthcoming_tracks", class_name: 'ScheduledTracks', relation_name: :forthcoming_tracks
end
```

## Side-loading data using the include URL parameter

Using the `include` URL parameter with a value of `forthcoming-tracks` includes the data in the standardised JSONAPI format.

`curl "http://0.0.0.0:3000/api/v1/schedules/test?include=forthcoming-tracks" -H 'Content-Type: application/vnd.api+json'`

```json
{
  "data": {
    "id": "test",
    "type": "schedules",
    "links": {
      "self": "http://0.0.0.0:3000/api/v1/schedules/test"
    },
    "attributes": {
      "name": "Test",
      "current-position": 0
    },
    "relationships": {
      "forthcoming-tracks": {
        "links": {
          "self": "http://0.0.0.0:3000/api/v1/schedules/test/relationships/forthcoming-tracks",
          "related": "http://0.0.0.0:3000/api/v1/schedules/test/forthcoming-tracks"
        },
        "data": [
          {
            "type": "scheduled-tracks",
            "id": "3"
          },
          {
            "type": "scheduled-tracks",
            "id": "4"
          }
        ]
      },
      "scheduled-tracks": {
        "links": {
          "self": "http://0.0.0.0:3000/api/v1/schedules/test/relationships/scheduled-tracks",
          "related": "http://0.0.0.0:3000/api/v1/schedules/test/scheduled-tracks"
        }
      }
    }
  },
  "included": [
    {
      "id": "3",
      "type": "scheduled-tracks",
      "links": {
        "self": "http://0.0.0.0:3000/api/v1/scheduled-tracks/3"
      },
      "attributes": {
        "position": 3,
        "state": "playing"
      }
    },
    {
      "id": "4",
      "type": "scheduled-tracks",
      "links": {
        "self": "http://0.0.0.0:3000/api/v1/scheduled-tracks/4"
      },
      "attributes": {
        "position": 4,
        "state": "queued"
      }
    }
  ]
}
```

Including data is this way can be very useful, often referred to as 'side-loading', to reduce the number of individual requests necessary to retrieve data.

## A note about caching responses

JSONAPI:Resources [now includes the ability to cache responses](http://jsonapi-resources.com/v0.10/guide/resource_caching.html).

To see this working first create an initializer

**config/initializers/jsonapi_resources.rb**
```ruby
JSONAPI.configure do |config|
  config.resource_cache = Rails.cache
end
```

Then add `caching` to the resources

**app/resources/api/v1/schedule_resource.rb**
```ruby
class Api::V1::ScheduleResource < JSONAPI::Resource
  caching
  #...
end
```

**app/resources/api/v1/scheduled_track_resource.rb**
```ruby
class Api::V1::ScheduledTrackResource < JSONAPI::Resource
  caching
  #...
end
```

In development mode caching isn't enabled by default, so it needs to be enabled.

```
⇒  bin/rails dev:cache
Development mode is now being cached.
```

After restarting the server the first response becomes cached for subsequent requests.

For the first request the queries are made...

```
Started GET "/api/v1/schedules/test?include=forthcoming-tracks" for 127.0.0.1 at 2017-11-20 15:13:55 +0100
   (1.0ms)  SELECT "schema_migrations"."version" FROM "schema_migrations" ORDER BY "schema_migrations"."version" ASC
Processing by Api::V1::SchedulesController#show as HTML
  Parameters: {"include"=>"forthcoming-tracks", "id"=>"test"}
   (0.6ms)  SELECT schedules.slug, schedules.updated_at FROM "schedules" WHERE "schedules"."slug" = $1  [["slug", "test"]]
   (7.2ms)  SELECT schedules.slug, scheduled_tracks.id, scheduled_tracks.updated_at FROM "schedules" INNER JOIN "scheduled_tracks" ON "scheduled_tracks"."schedule_id" = "schedules"."id" AND "scheduled_tracks"."state" IN ('playing', 'next', 'queued') WHERE "schedules"."slug" = 'test' ORDER BY scheduled_tracks.id asc
  Schedule Load (0.5ms)  SELECT "schedules".* FROM "schedules" WHERE "schedules"."slug" = 'test'
  ScheduledTrack Load (6.4ms)  SELECT "scheduled_tracks".* FROM "scheduled_tracks" WHERE "scheduled_tracks"."id" IN (3, 4)
  Rendering text template
  Rendered text template (0.0ms)
Completed 200 OK in 112ms (Views: 5.8ms | ActiveRecord: 51.0ms)
```

But for subsequent requests the cache is used...

```
Started GET "/api/v1/schedules/test?include=forthcoming-tracks" for 127.0.0.1 at 2017-11-20 15:14:04 +0100
Processing by Api::V1::SchedulesController#show as HTML
  Parameters: {"include"=>"forthcoming-tracks", "id"=>"test"}
   (2.1ms)  SELECT schedules.slug, schedules.updated_at FROM "schedules" WHERE "schedules"."slug" = $1  [["slug", "test"]]
   (0.5ms)  SELECT schedules.slug, scheduled_tracks.id, scheduled_tracks.updated_at FROM "schedules" INNER JOIN "scheduled_tracks" ON "scheduled_tracks"."schedule_id" = "schedules"."id" AND "scheduled_tracks"."state" IN ('playing', 'next', 'queued') WHERE "schedules"."slug" = 'test' ORDER BY scheduled_tracks.id asc
  Rendering text template
  Rendered text template (0.0ms)
Completed 200 OK in 11ms (Views: 0.3ms | ActiveRecord: 2.6ms)
```

This is a very powerful way of ensuring a fast, responsive API server with minimal effort required.

Whilst important to know for production, it is simpler to begin development without the additional cognitive overhead of possible caching issues.

```
⇒  bin/rails dev:cache
Development mode is no longer being cached.
```

## Testing customized has_many relationships

Using a similar approach RSpec can ensure that the response matches the customized relationship.

In this test there should be only two forthcoming tracks (the third scheduled-track added is in state "queued" by default) and the relationship data included.

**spec/requests/schedules_spec.rb**
```ruby
describe "GET /api/v1/schedules/id?include=forthcoming-tracks" do
  it "includes forthcoming tracks relationship and data" do
    schedule = Schedule.create(name: "Test")
    ScheduledTrack.create(position: 1, state: "played", schedule: schedule)
    ScheduledTrack.create(position: 2, state: "playing", schedule: schedule)
    ScheduledTrack.create(position: 3, schedule: schedule)
    get "/api/v1/schedules/test?include=forthcoming-tracks"
    json = response.body
    expect(json).to have_json_path("data/relationships/forthcoming-tracks")
    expect(json).to have_json_size(2).at_path("included")
  end
end
```

## Creating models and validation

Currently it is possible to create a `schedule` model without including a name attribute.

```
curl -X "POST" "http://0.0.0.0:3000/api/v1/schedules" \
     -H 'Content-Type: application/vnd.api+json' \
     -d $'{
  "data": {
    "type": "schedules",
    "attributes": {}
  }
}'
```

But this returns a model with `null` for the `id` and `name` attribute which is a major issue.

Standard ActiveRecord model validations can prevent this from occurring.

```ruby
class Schedule < ApplicationRecord
  #...
  validates_presence_of :name
end
```

JSONAPI:Resources uses these validations to provide meaningful JSON error responses.

```
{
  "errors": [
    {
      "title": "can't be blank",
      "detail": "name - can't be blank",
      "code": "100",
      "source": {
        "pointer": "/data/attributes/name"
      },
      "status": "422"
    }
  ]
}
```

Writing tests also demonstrate that a content-type of `'application/vnd.api+json'` must be used along with the correct JSON payload. Details are all available from the [JSONAPI specification](http://jsonapi.org/format/#conventions).

**spec/requests/schedules_spec.rb**
```ruby
require 'rails_helper'

RSpec.describe "Schedules", type: :request do
  #...
  describe "POST /api/v1/schedules" do
    it "returns error if there is no content-type" do
      post "/api/v1/schedules"
      error_message = %({
        "errors": [
          {
            "title": "Unsupported media type",
            "detail": "All requests that create or update must use the 'application/vnd.api+json' Content-Type. This request specified 'application/x-www-form-urlencoded'.",
            "code": "415",
            "status": "415"
          }
        ]
      })
      expect(response).to have_http_status(415)
      expect(response.body).to be_json_eql(error_message)
    end

    it "returns error if there is no name attribute" do
      post_data = {
        data: {
          type: "schedules",
          attributes: {}
        }
      }.to_json
      post "/api/v1/schedules", params: post_data, headers: { 'Content-Type': 'application/vnd.api+json' }
      error_message = %({
        "errors": [
          {
            "title": "can't be blank",
            "detail": "name - can't be blank",
            "code": "100",
            "source": {
              "pointer": "/data/attributes/name"
            },
            "status": "422"
          }
        ]
      })
      expect(response).to have_http_status(422)
      expect(response.body).to be_json_eql(error_message)
    end

    it "creates a new schedule if name is included" do
      post_data = {
        data: {
          type: "schedules",
          attributes: {
            name: "Test 3"
          }
        }
      }.to_json
      post "/api/v1/schedules", params: post_data, headers: { 'Content-Type': 'application/vnd.api+json' }
      expect(response).to have_http_status(201)
      json = response.body
      expect(json).to have_json_path("data")
      expect(json).to be_json_eql(%("test-3")).at_path("data/id")
    end
  end
end
```

Now `schedule` models can now be created successfully via the JSONAPI, ensuring that they have a name attribute.
