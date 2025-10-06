OpenSplitTime
================

OpenSplitTime is a site for endurance athletes, fans and families, race directors, volunteers, support crews, and data geeks. Our purpose is simple: to make it easy to collect endurance event data, play with it, plan with it, safely archive it, and never worry about it again.

The site is built and maintained by OpenSplitTime Company, a Colorado nonprofit corporation. If you find the website useful, motivating, entertaining, or strangely beautiful, please consider making a small [donation](https://www.opensplittime.org/donations) to help us keep the doors open. OpenSplitTime Company is registered with the U.S. Internal Revenue Service as a 501(c)(3) charitable organization. Your donations are probably tax deductible (but if you have any question you should ask your tax advisor about that stuff).

Our software engine is open source. If you have a suggestion for the site, or you are a software engineer and would like to help with development, or if you are a race director or data geek and would like to be a beta tester, please [contact us](mailto:mark@opensplittime.org) and let's talk.

OpenSplitTime is developed and maintained by endurance athletes for endurance athletes.

Ruby on Rails
-------------

This application requires:

- Ruby 3.4
- Rails 7.2

Learn more about [Installing Rails](https://gorails.com/setup/osx/10.12-sierra).

Getting Started
---------------
### Setup Local Environment

**Homebrew (MacOS)**
1. Install [Homebrew](http://brew.sh/).

**Ruby**

1. Clone the repository to your local machine by [forking the repo](https://help.github.com/articles/fork-a-repo/)
2. Install rbenv:

> ### Using Homebrew on MacOS
> - Install Homebrew http://brew.sh/
> - `$ brew update`
> - `$ brew install rbenv`

> ### Using Debian/Ubuntu (Instructions from [DigitalOcean](https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-18-04))
> - Install dependencies `$ sudo apt install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm5 libgdbm-dev`
> - Clone the rbenv repository `$ git clone https://github.com/rbenv/rbenv.git ~/.rbenv`
> - Add to path `$ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc`
> - Enable automatic loading `$ echo 'eval "$(rbenv init -)"' >> ~/.bashrc`
> - Apply changes to current terminal `$ source ~/.bashrc`
> - Add ruby-build plugin `$ git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build`

3. `$ cd` into your local `OpenSplitTime` directory
4. `$ rbenv init` For any questions around setting up rbenv see https://github.com/rbenv/rbenv
5. `$ rbenv install <current ruby version>`
6. `$ rbenv rehash` then restart the terminal session

**Rails, Gems, Databases**

1. `$ gem install bundler` You should not need to `sudo` this. If it says "permission denied" [rbenv is not setup correctly](https://github.com/rbenv/rbenv/issues/670)
2. Install Postgres and Redis

> ### Using Homebrew on MacOS
> `$ brew install postgres redis`

> ### Using Debian/Ubuntu
>  - `$ sudo apt install postgresql libpq-dev redis-server`
>  - Setup your user (same as login) `$ sudo -u postgres createuser --interactive`

3. `$ bundle install`

*if running into weird errors first try `$ rbenv rehash` and restart your terminal*

**Javascript Runtime + Yarn**

1. Install Node.js v16 (the latest LTS as of mid-2022). We recommend using [`nvm`](https://github.com/nvm-sh/nvm). Otherwise:
- Using MacOS: You can download the package installer from nodejs.org.
- Using Debian/Ubuntu: `wget -qO- https://deb.nodesource.com/setup_16.x | sudo -E bash - && sudo apt-get install -y nodejs`

2. Install Yarn

After ensuring you're using the right version of Node.js (with `node --version`): `npm install -g yarn`

**Database**

1. Start your local DB `$ brew services restart postgres && brew services restart redis` or run the Postgres App
2. `$ rails db:setup` to create the database
3. `$ rails db:from_fixtures` to load seed data from test fixtures files
4. `$ rails s` to start the server
5. Type `localhost:3000` in a browser

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

**Sidekiq**

OpenSplitTime relies on Sidekiq for background jobs, and Sidekiq needs Redis. Make sure your Redis server (installed above) is started. Run your Sidekiq server from the command line:

`$ sidekiq`

You'll know you did it right when you see the awesome ASCII art.

**ChromeDriver**

Some integration tests rely on Google ChromeDriver. You can install it in Mac OS X with `brew cask install chromedriver` or your preferred package 
manager for Linux or Windows. You will also need to have Chrome installed on your system.

**Continuous Integration**

Heroku CI and Github Actions are both used to ensure tests are passing. The status of your branch will be indicated in github. 
Please ensure your branch is passing before making a pull request.

**Fontawesome 6**

OpenSplitTime uses Fontawesome 6 Pro for icons. Fontawesome icons are self-hosted. CSS is found in the repository at 
`app/assets/stylesheets/vendor/fontawesome`, and the font files are found at `app/assets/fonts` (all fonts beginning with `fa-` 
are Fontawesome fonts).

To update Fontawesome, you will need credentials. Contact the repository maintainers to obtain credentials. Select the OpenSplitTime Kit and add the 
needed icons from the "Solid," "Regular," or "Brands" collections using the Kit update tool, then download the kit. 

Copy only the following files from the downloaded kit:

```
scss/_variables.scss -> app/assets/stylesheets/vendor/fontawesome/_variables.scss
webfonts/*.* -> app/assets/fonts
```

If you need to add icons from another collection (such as "Light"), you will need to add the corresponding stylesheet (such as `light.scss`) to the
`app/assets/stylesheets/vendor/fontawesome` directory and `@include` that stylesheet from the `app/assets/stylesheets/application.bootstrap.scss` file.

In addition, note that the new css file (`light.scss` in our example) will have an incorrect URL for the font files. You will need to edit the URL to
match the URLs used in the other Fontawesome stylesheets.

Starting the Server
-------------------------

To start the development server and workers, and to compile JavaScript and CSS files (and start watchers that will recompile them as they change), 
navigate to the OpenSplitTime directory and type:
```
$ bin/dev
```

Support
-------------------------

Still having issues setting up your local environment?
Create an [issue](https://github.com/SplitTime/OpenSplitTime/issues/new) with label `support` and we will try and help as best we can!

Contributing
-------------

We love Issues but we love Pull Requests more! If you want to change something or add something feel free to do so. If you don't have enough time or skills start an issue. Below are some loose guidelines for contributing.

### Pull Requests

Writing code for something is the fastest way to get feedback. It doesn't matter if the code is a work in progress or just a spike of an idea we'd love to see it. Testing is critical to our long-term success, so code submissions must include tests covering all critical logic. :heart:

### Issues

Be detailed. They only person who knows the bug you are experiencing or feature that you want is you! So please be as detailed as possible. Include labels like `bug` or `enhancement` and you know the saying a picture is worth a thousand words. So if you can grab a screenshot or gif of the behavior even better!


Credits
-------

This application was originally generated back in 2015 with the [rails_apps_composer](https://github.com/RailsApps/rails_apps_composer) gem
provided by the [RailsApps Project](http://railsapps.github.io/).

Rails Composer is supported by developers who purchase the RailsApps tutorials.

License
-------

[The MIT License](https://github.com/SplitTime/OpenSplitTime/blob/master/LICENSE)

Copyright
---------

Copyright (c) 2015-2025 OpenSplitTime Company. See license for details.
