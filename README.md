# Capistrano::Buildpack

Deploy [12-factor](http://www.12factor.net/) applications using Capistrano.

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-buildpack'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-buildpack

## Usage

Here's a basic Capfile that uses `Capistrano::Buildpack`:

    require 'rubygems'

    set :application, "bugsplatdotinfo"
    set :repository, "https://github.com/peterkeen/bugsplat.rb"
    set :scm, :git
    set :additional_domains, ['bugsplat.info']
    
    role :web, "examplevps.bugsplat.info"
    set :buildpack_url, "https://github.com/peterkeen/bugsplat-buildpack-ruby-simple"
    
    set :user, "peter"
    set :base_port, 6700
    set :concurrency, "web=1"

    read_env 'prod'
   
    load 'deploy'
    require 'capistrano-buildpack'
    
This will load a file named `.env.prod` which should consist of environment variables like this:

    SOME_VAR_NAME=some_value
    SOME_OTHER_VAR=something_else
    
This example just unconditionally loads 'prod' but you can have as many different sets as you want,
loading them as appropriate in tasks.
    
To run a deploy:

    $ cap deploy:setup # create the required directory structure and gem install foreman-export-nginx
    $ cap deploy       # actually run a deploy
    
Deploy will do the following things:

* Create the required directory structure at `/apps/<application>`
* Clone/update the buildpack
* Clone/update the code repository
* Apply the buildpack to the code repository
* Create `upstart`-style init files in `/etc/init` and start up the app
* Create an nginx config file at `/etc/nginx/conf.d/<application>.conf and restart nginx

The nginx config will list at least one domain for the app: `<application>.<hostname>`, which in this case is `bugsplatdotinfo.examplevps.bugsplat.info`. Anything
you add to the `:additional_domains` setting gets tacked on at the end.

Several other settings are available:

* `use_ssl`: true to listen on port 443
* `ssl_cert_path`: a path to a certificate file on the server. You are responsible for getting the certificate there.
* `ssl_key_path`: a path to a key file on the server. You are responsible for getting it there.
* `force_ssl`: Force a redirect to SSL. This will unconditionally redirect to the first domain in `additional_domains`, so if you have multiple you may want to do this in your app instead.
* `force_domain`: Force a redirect to the given domain.

To run your app as a different user than `:user`, use the `:app_user` setting. This user will not be created for you, you'll need to create it yourself, and it must have a proper home directory.

## Running remote commands

Sometimes you want to run a command on the other end that isn't defined in a Procfile. Do that with `cap remote`:

    $ cap remote echo hi there

## Very Important Notes

`Capistrano::Buildpack` will *not* run `bin/release` from the buildpack, so any environment variables that that attempts to set need to be set using `read_env`.
In addition, at the moment the exported nginx config does not have compression turned on.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
