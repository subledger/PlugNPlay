# Plug N' Play

This project is a Rails application that should be used as reference for integrating with the Subledger API.

It makes integrating with Subledger easier than ever, by encapsulating your accounting logic into single API calls, which in turn make the calls to the lower level Subledger APIs. It also handles mapping between your transactions, customers, vendors, products and your Subledger accounts and journal entry ids (optional).

It should be deployed as a standalone App, and accessed by means of the API it exposes. To make thigs even simplier, we also provide an HTTP client for the API, so you just need to do add the client gem to your Gemfile, and make the calls at the right place, passing the right data.

The example client code can be found at:
https://github.com/subledger/PlugNPlay/tree/atpay/clients/ruby

The accounting logic can be found at:
https://github.com/subledger/PlugNPlay/blob/atpay/app/services/subledger_service.rb


## Demo App Requirements

This project is using:

* Ruby: 2.0.0-p247
* Rails: 4.0.1 


## Demo App Setup

After cloning the project, run the following commands on project root dir:

```
bundle install
bundle exec rake db:create
bundle exec rake db:migrate
```

Please note that you may need to setup values on config/database.yml before running db:setup.


## Running the App

```
bundle exec rails s
```

This will start app on http://localhost:3000.
By accessing this url the first time, it will guide you through the process of creating credentials for using Subledger API.
