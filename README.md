# Rails Docker Base

This is a template for creating Docker based Rails development environments.

## Get Started

```bash
docker-compose run --no-deps rails rails new . --skip-spring --skip-bootsnap --skip-coffee --webpack=stimulus --database=mysql
```

Select `n` when asked to override the `README.md` and `Gemfile`:

```bash
	exist
	conflict  README.md
Overwrite /usr/src/app/README.md? (enter "h" for help) [Ynaqdhm] n
	skip  README.md
	create  Rakefile
	create  .ruby-version
	create  config.ru
	create  .gitignore
	conflict  Gemfile
Overwrite /usr/src/app/Gemfile? (enter "h" for help) [Ynaqdhm] n
```
## Setup

### Database

Update the `config/database.yml` with the correct database credientials and create the database, and create the database within the database container using the connection details provided. Please note the `host` field is set to `db`, the database container name:

```yml
adapter: mysql2
encoding: utf8mb4
pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
username: root
password: root
host: database
```

### Gems

Add the Gems you want, ie:

```Gemfile
gem "anycable-rails", "~> 1.0"
gem "connection_pool"
gem "hiredis"
gem 'redis', '~> 4.0', require: ["redis", "redis/connection/hiredis"]
gem "sidekiq"
gem "stimulus_reflex"

group :development, :test do
	gem 'pry-byebug'
end
```

Note, you will have to run `docker-compose up --build` after adding Gems. If the container is running you can run `docker-compose exec rails bundle install`

### Sidekiq

Update the `sidekiq.yml` with any additionally required queues:

```yml
---
:concurrency: 5
staging:
	:concurrency: 10
production:
	:concurrency: 20
:queues:
	- critical
	- default
	- low
```

### Action Cable

Add the following to your `application.html.erb`

```erb
<%= action_cable_meta_tag %>
```

By default this is set to `async`, however a Redis server is available, and required if you wish to send broadcasts outside the local process, from the `rails console` for instance.

Change `ACTION_CABLE_ADAPTER` to  `redis`.

#### AnyCable

Setup AnyCable by running the following command:

```bash
docker-compose run --no-deps rails rails g anycable:setup
```

```bash
👋 Welcome to AnyCable interactive installer.
  conflict  config/cable.yml
Overwrite /usr/src/app/config/cable.yml? (enter "h" for help) [Ynaqdhm] y
	 force  config/cable.yml
	create  config/anycable.yml
	  info  ✅ 'config.action_cable.url' has been configured
```

You can skip the rest of the installation. Inside of `anycable.yml` change `rpc_host: "127.0.0.1:50051"` to `rpc_host: "0.0.0.0:50051"`

### Webpacker

You will need to change two keys in the `webpacker.yml` file, the `host` and `public` keys, as so:

```yml
dev_server:
	host: webpacker
	public: 0.0.0.0:3035
```

Add the following line to your `application.html.erb`:

```erb
<%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
```

In your `app/javascripts/packs/application.js` all the following line:

```js
import "../css/application.scss"
```

Then create a file `app/javascript/css/application.scss` and add/import any application css in there to have it served and compiled by webpacker.

### Searchkick

If you are using Searchkick, add the initialier to `config/initializers/searchkick.rb` and add the following:

```ruby
Searchkick.client = Elasticsearch::Client.new(hosts: ["elasticsearch:9200"], retry_on_failure: true)
```

### Vips

Vips is installed on the image, to test Vips, go into the rails container `docker-compose exec rails bash`, then move to the public directory `cd /usr/src/app/public`. If you add an image file here, for example called "1.jpg", then you can use the following to rotate it 90 degrees and save it as "2.jpg", `vips rot 1.jpg 2.jpg d90`.

### Development Web Console

To get the web console working from within the Docker container, add the following to your `application.rb`

```rb
config.web_console.whitelisted_ips = ['172.16.0.0/12', '192.168.0.0/16']
```

### Adding Yarn/NPM packages

To add new packages with Yarn, use the following on the command line:

```bash
docker-compose exec rails yarn add <package>
```

## Finalising the container

The container was built during the `run` process which created the Rails app, but we need to bring them up and copy all the new Gems and Node packages over:

```bash
docker-compose up --build
```

## Changing Rails configuration

If you wish to make changes to Rails configuration files, use:

```bash
docker-compose stop rails
docker-compose start rails
```

This will bring the container up in the background with the new configuration.

## Executing commands

To execute a command on a running container, use the following command:

```bash
# docker-compose exec <container_name> <command>
docker-compose exec rails rails db:migrate
```

## Debugging

Byebug/Pry wont work with a normal container running, to get around this, you can start the containers in the background with the `-d` flag, then manually attach to the running rails container:

```bash
docker-compose up -d; docker attach rails_docker_base_rails_1
```
