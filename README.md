# Plug N' Play

This project is a Rails application that should be used as reference for integrating with Subledger services.

It contains a rake task to help performing the initial project setup:

https://github.com/subledger/PlugNPlay/blob/master/lib/tasks/subledger.rake


And also services that encapsulate accounting logic and entities mapping from integrating App to Subledger:

https://github.com/subledger/PlugNPlay/tree/master/app/services

Integration should be performed by calling the methods exposed on money_service.rb. Examples of use of this methods can be found at:

https://github.com/subledger/PlugNPlay/blob/master/app/controllers/simulate_controller.rb#L15

https://github.com/subledger/PlugNPlay/blob/master/app/controllers/simulate_controller.rb#L35

## Demo App Requirements

This project is using:

* Ruby: 2.0.0-p247
* Rails: 4.0.1 


## Demo App Setup

After cloning the project, run the following commands on project root dir:

```
bundle install
bundle exec rake db:setup
```

Please note that you may need to setup values on config/database.yml before running db:setup.


## Running the App

```
bundle exec rails s
```

This will start app on http://localhost:3000
