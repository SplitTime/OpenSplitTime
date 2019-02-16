OpenSplitTime
================

OpenSplitTime is a site for endurance athletes, fans and families, race directors, volunteers, support crews, and data geeks. Our purpose is simple: to make it easy to collect endurance event data, play with it, plan with it, safely archive it, and never worry about it again. 

The site is built and maintained by OpenSplitTime Company, a Colorado nonprofit corporation. If you find the website useful, motivating, entertaining, or strangely beautiful, please consider making a small [donation](https://www.opensplittime.org/donations) to help us keep the doors open. OpenSplitTime Company is registered with the U.S. Internal Revenue Service as a 501(c)(3) charitable organization. Your donations are probably tax deductible (but if you have any question you should ask your tax advisor about that stuff).

Our software engine is open source. If you have a suggestion for the site, or you are a software engineer and would like to help with development, or if you are a race director or data geek and would like to be a beta tester, please [contact us](mailto:mark@opensplittime.org) and let's talk.

OpenSplitTime is developed and maintained by endurance athletes for endurance athletes.

Ruby on Rails
-------------

This application requires:

- Ruby 2.6.0
- Rails 5.2.2

Learn more about [Installing Rails](https://gorails.com/setup/osx/10.12-sierra).

Getting Started
---------------
### Setup Local Environment

**Homebrew (MacOS)**
1. Install [Homebrew](http://brew.sh/).

**Ruby**

1. Clone the repository to your local machine by [forking the repo](https://help.github.com/articles/fork-a-repo/)
2. Install rbenv...

> ### Using Homebrew on MacOS
> 1. Install Homebrew http://brew.sh/
> 2. `$ brew update`
> 3. `$ brew install rbenv`

> ### Using Debian/Ubuntu (Instructions from [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-18-04))
> 1. Install dependancies `$ sudo apt install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev`
> 2. Clone the rbenv repository `$ git clone https://github.com/rbenv/rbenv.git ~/.rbenv`
> 3. Add to path `$ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc`
> 4. Enable automatic loading `$ echo 'eval "$(rbenv init -)"' >> ~/.bashrc`
> 5. Apply changes to current terminal `$ source ~/.bashrc`
> 6. Add ruby-build plugin `$ git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build`

3. `$ cd` into your local `OpenSplitTime` directory
4. `$ rbenv init` For any questions around setting up rbenv see https://github.com/rbenv/rbenv
5. `$ rbenv install 2.6.0`
6. `$ rbenv local 2.6.0` (to make sure this is correct, run `$ rbenv version`)
7. `$ rbenv rehash` then restart the terminal session

**Rails and Gems**

1. `$ gem install bundler` You should not need to `sudo` this. If it says "permission denied" [rbenv is not setup correctly](https://github.com/rbenv/rbenv/issues/670)
2. `$ gem install rails`
3. Install Postgres...

> ### Using Homebrew on MacOS
> 1. `$ brew install postgres`

> ### Using Debian/Ubuntu
> 1. `$ sudo apt install postgresql libpq-dev`
> 2. Setup your user (same as login) `$ sudo -u postgres createuser --interactive`

4. `$ bundle install`

*if running into weird errors first try `$ rbenv rehash` and restart your terminal*

**Javascript Runtime + Yarn**

1. Install Node.js

> ### Using Homebrew on MacOS
> *Incomplete*

> ### Using Debian/Ubuntu
> 1. Configure repository `wget -qO- https://deb.nodesource.com/setup_8.x | sudo -E bash -`
> 3. Install Node.js `sudo apt-get install -y nodejs`

2. Install Yarn

> ### Using Homebrew on MacOS
> 1. `brew install yarn`

> ### Using Debian/Ubuntu
> 1. Configure yarn repository...
> 2. `curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -`
> 3. `echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list`
> 4. `sudo apt-get update && sudo apt-get install yarn`
> 5. `$ cd` into your local `OpenSplitTime` directory
> 6. Update dependancies `$ yarn`
>
> *If you have any issues, refer to [yarn's website](https://yarnpkg.com/lang/en/docs/install)*

**Database**

1. Start your local DB `$ brew services restart postgres`
2. `$ rake db:setup` to create the database
3. `$ rails db:structure:load` to add Postgres functions
4. `$ rails db:from_fixtures` to load seed data from test fixtures files
5. `$ rails s` to start the server
6. Type `localhost:3000` in a browser

*Test Users*

After you setup/seed your database, you should have four test users:
```
| Role  | Email                  | Password |
| ----- | ---------------------- | -------- |
| admin | user@example.com       | password |
| user  | thirduser@example.com  | password |
| user  | fourthuser@example.com | password |
| user  | fifthuser@example.com  | password |
```

**AWS**

OpenSplitTime relies on Amazon Web Services for file import and storage and for SNS (email and text) communications. To take full advantage of these, you will need AWS credentials loaded into your `.env` file, specifically:
```
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=your_aws_region
S3_BUCKET=your_aws_bucket
```
Use your own credentials or contact us if you would like to use the dev group's credentials.

**Pusher**

OpenSplitTime uses Pusher for messaging with workers and to notify Live Entry operators of times that need attention. Specifically, you will need to add the following to your `.env` file:
```
PUSHER_APP_ID=xxx
PUSHER_KEY=xxx
PUSHER_SECRET_KEY=xxx
```
Contact us for the dev team's Pusher credentials.

**Sidekiq and Redis**

OpenSplitTime relies on Sidekiq for background jobs, and Sidekiq needs Redis. Install Redis using the simple instructions you'll find at [redis.io](https://redis.io). Run your Sidekiq server from the command line:

`$ sidekiq`

You'll know you did it right when you see the awesome ASCII art.

**ChromeDriver**

Some integration tests rely on Google ChromeDriver. You can install it in Mac OS X with `brew install chromedriver` or your preferred package manager for Linux or Windows.

Support
-------------------------

Still having issues setting up your local environment? 
Create an [issue](https://github.com/SplitTime/OpenSplitTime/issues/new) with label `support` and we will try and help as best we can!

Contributing
-------------

We love Issues but we love Pull Requests more! If you want to change something or add something feel free to do so. If you don't have enough time or skills start an issue. Below are some loose guidlines for contributing.

### Pull Requests

Writing code for something is the fastest way to get feedback. It doesn't matter if the code is a work in progress or just a spike of an idea we'd love to see it. Testing is critical to our long-term success, so code submissions must include tests covering all critical logic. :heart:

### Issues

Be detailed. They only person who knows the bug you are experiencing or feature that you want is you! So please be as detailed as possible. Include labels like `bug` or `enhancement` and you know the saying a picture is worth a thousand words. So if you can grab a screenshot or gif of the behavior even better!


Credits
-------

This application was generated with the [rails_apps_composer](https://github.com/RailsApps/rails_apps_composer) gem
provided by the [RailsApps Project](http://railsapps.github.io/).

Rails Composer is supported by developers who purchase our RailsApps tutorials.

Problems? Issues?
-----------

Need help? Ask on Stack Overflow with the tag 'railsapps.'

Your application contains diagnostics in the README file. Please provide a copy of the README file when reporting any issues.

If the application doesn't work as expected, please [report an issue](https://github.com/RailsApps/rails_apps_composer/issues)
and include the diagnostics.

License
-------

[The MIT License](https://github.com/SplitTime/OpenSplitTime/blob/master/LICENSE)

Copyright
---------

Copyright (c) 2015-2019 OpenSplitTime Company. See license for details.