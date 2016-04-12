# Web interface for the Microbial Genomes Atlas (MiGA)


## Ruby version

We have tested MiGA Web with Ruby 2.2.3, but any 2.x (and perhaps 1.9) should
be compatible.

## System dependencies

Make sure you have bundle `gem install bundle`. Next, execute:

```bash
git clone https://github.com/bio-miga/miga-web.git
cd miga-web
bundle
```

## Deployment instructions

Once your MiGA Web is ready with all the dependencies, you can start the server. First,
prepare the system:

```bash
# Tell rails this is a production server:
export RAILS_ENV=production
# create an empty folder to host your projects (it can be anywhere in your computer):
mkdir $HOME/miga-data
# Generate the initial database:
rake db:migrate
# Precompile assets:
rake assets:precompile
```

Next, launch the server. We have had a great experience with Puma, so that's what we use.
You only need to specify where the data is:

```bash
export SECRET_KEY_BASE=`rake secret`
export MIGA_PROJECTS=$HOME/miga-data
export MAIL_HOST=localhost
rails s -e production Puma
```

Now you can visit your MiGA Web interface at [http://localhost:3000/](http://localhost:3000/).
To use a world-accessible address, simply set the mail host to that address, and pass it to
rails using -b.
For example, this is how we launch our own [MiGA Web](http://enve-omics.ce.gatech.edu:3000):

```bash
export SECRET_KEY_BASE=`rake secret`
export MIGA_PROJECTS=$HOME/miga-data
export MAIL_HOST=enve-omics.ce.gatech.edu
rails s -e production -b $MAIL_HOST Puma
```

## Create admin users

Once you create your first user, you may want to make it an admin. You can do so from the
console:

```ruby
RAILS_ENV=production rails c
irb> u = Users.find(1) # Change the 1 for the actual ID of your user
irb> u.admin = true
irb> u.save
```

## How to run the test suite

Execute `bundle exec rake test`.

