[![Code Climate](https://codeclimate.com/github/bio-miga/miga-web/badges/gpa.svg)](https://codeclimate.com/github/bio-miga/miga-web)
[![Test Coverage](https://codeclimate.com/github/bio-miga/miga-web/badges/coverage.svg)](https://codeclimate.com/github/bio-miga/miga-web/coverage)
[![Build Status](https://travis-ci.org/bio-miga/miga-web.svg?branch=master)](https://travis-ci.org/bio-miga/miga-web)
[![Inch docs](http://inch-ci.org/github/bio-miga/miga-web.svg)](http://inch-ci.org/github/bio-miga/miga-web)

# Web interface for MiGA

## Ruby version

We test MiGA Web with Ruby 2.x (MRI). Some gems used in the rails backend are
unavailable for Ruby < 2.0.

## System dependencies

First, make sure you have bundle:

```bash
gem install bundle
```

Next, get `miga-web` and all its dependencies:

```bash
git clone https://github.com/bio-miga/miga-web.git
cd miga-web
bundle
```

## Deployment instructions

### 1. Preparations

Once your MiGA Web is ready, you can start the server. First, prepare the
system:

```bash
# Tell rails this is a production server:
export RAILS_ENV=production
# create an empty folder to host your projects (it can be anywhere):
mkdir $HOME/miga-data
# Generate the initial database:
bundle exec rake db:migrate
# Precompile assets:
bundle exec rake assets:precompile
```

### 2. Settings

Next, configure the server. Simply copy `config/settings.yml` to
`config/settings.local.yml` and modify the necessary variables. If you modified
the data location above (folder to host your projects), make sure to set the
correct path for `miga_projects`.

### 3. Launch

Finally, launch the server. We have had a great experience with Puma, so that's
what we use.

```bash
export SECRET_KEY_BASE=`bundle exec rake secret`
rails s -e production Puma
```

Now you can visit your MiGA Web interface at
[localhost:3000](http://localhost:3000/). To use a world-accessible address,
simply set the mail host to that address, and pass it to rails using -b and -p.
For example, this is how we launch our own
[MiGA Web](http://enve-omics.ce.gatech.edu:3000):

```bash
export SECRET_KEY_BASE=`bundle exec rake secret`
rails s -e production -b enve-omics.ce.gatech.edu -p 3000 Puma
```

## Create admin users

Once you create your first user from the website, you may want to make it an
admin. You can do so from the console:

```ruby
RAILS_ENV=production rails c
irb> u = User.find(1) # Change the 1 for the actual ID of your user
irb> u.admin = true
irb> u.save
```

## How to run the test suite

Execute `bundle exec rake test`.

