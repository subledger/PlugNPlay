# Sports Ngin Subledger Integration Demo

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
bundle
rake db:setup
```

Please note that you may need to setup values on config/database.yml before running db:setup.


## Subledger Integration Setup

Before the Subledger integration can be used, some initial setup is needed to:

* Create your credentials to use Subledger API
* Create an Organization
* Create a Book
* Create global Accounts for Revenue and Cash
* Setup Reporting

To make things much simpler, the following rake task will handle all the work:
```
bundle exec rake subledger:setup["<email address>","<account description>","<org description>","<book description>"]
```

Just replace the <> with your values, for example:
```
bundle exec rake subledger:setup["example@test.com","Test Account","Test Org","Test Book"]
```

Running this rake task successfully will output something similar to the following:
```
* Installing Subledger and running initial setup...
  - Creating Identity...
  - Creating Org...
  - Creating Book...
  - Creating Global Account...
  - Creating Global Account...
  - Creating Report...

* You are all set!
* Just add/set the the following environment variables and restart your app:
SUBLEDGER_KEY_ID='XtXe6E5uiNRvE8P1S8nrJ5'
SUBLEDGER_SECRET='X4gmK1bEAluIfhZZnHk2K3'
SUBLEDGER_ORG_ID='9aJshijZQuDVSMIiiTV8t6'
SUBLEDGER_BOOK_ID='kV3UHsotxSeOpvOI8Cd5y6'
SUBLEDGER_REVENUE_ACCOUNT_ID='H2sbNiPt0ER51D97RMSRs1'
SUBLEDGER_CASH_ACCOUNT_ID='AMwlPPiRedxcpmDEbCQ6O6'
SUBLEDGER_AR_CATEGORY_ID='oXDnVBjEPEGQuf07IDMY44'
SUBLEDGER_AP_CATEGORY_ID='0jt5jj3G8eAeyvcJ4vJTtD'

* We will also map your app customer and organizations accounts
to Subledger specific accounts. For this to work, we will need to
create an YAML file. Please specify the full file path in an env
variable:
SUBLEDGER_ACCOUNTS_MAPPING_FILE=''

Example:
SUBLEDGER_ACCOUNTS_MAPPING_FILE='/opt/myapp/config/subledger_accounts_mapping.yml'

All done. Enjoy!
```

The mentioned environment variables needs to be exported before the application runs. There are many ways to do this, but for testing it is possible to create a file, like config/creds, and add this values in there prefixed with export:

```
export SUBLEDGER_KEY_ID='XtXe6E5uiNRvE8P1S8nrJ5'
export SUBLEDGER_SECRET='X4gmK1bEAluIfhZZnHk2K3'
export SUBLEDGER_ORG_ID='9aJshijZQuDVSMIiiTV8t6'
export SUBLEDGER_BOOK_ID='kV3UHsotxSeOpvOI8Cd5y6'
export SUBLEDGER_REVENUE_ACCOUNT_ID='H2sbNiPt0ER51D97RMSRs1'
export SUBLEDGER_CASH_ACCOUNT_ID='AMwlPPiRedxcpmDEbCQ6O6'
export SUBLEDGER_AR_CATEGORY_ID='oXDnVBjEPEGQuf07IDMY44'
export SUBLEDGER_AP_CATEGORY_ID='0jt5jj3G8eAeyvcJ4vJTtD'
export SUBLEDGER_ACCOUNTS_MAPPING_FILE='/home/michetti/ngin/config/subledger_accounts_mapping.yml'
```

After creating this file, run the following on the same terminal window where your rails app will be executed, from project root:
```
source config/creds
```

And then run the rails application from project root:
```
bundle exec rails s
```

This will start app on http://localhost:3000

If the environment variables were configured correctly, the app initial page should show their values and also a link to access the Subledger app related to this credentials. From there, you can see the activity feed and also generate reports.
