# Rails Docker Base

This is a template for creating Docker based Rails development environments.

## Todo

+ Add VIPs for image processing from builder
+ Add Elasticsearch/Kibana
+ Add WKD HTML for PDF generation

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

Update the `config/database.yml` with the correct database credientials and create the database, and create the database within the database container using the connection details provided.
Please note the `host` field is set to `db`, the database container name:

```yml
adapter: mysql2
encoding: utf8mb4
pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
username: root
password: root
host: db
```

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

 ## Finalise the container

 The container was built during the `run` process which created Rails, but we need to bring them up and copy all the new Gems and Node packages over:

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
