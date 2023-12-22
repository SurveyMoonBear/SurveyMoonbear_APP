# Testing an app on Heroku new stack
- method1: 
    Review apps ( but we are not review apps, so we used method 2 )
- method2: 
    Manually created test app under surveymoonbear as following steps
## step1 Creating a test app
```
$ heroku create --remote heroku-20 --stack heroku-20 <your app name>
```

Git remote named “heroku-20”

## step2  Migrating add-ons and config vars
You should Get Remote Access first :
Create a Heroku remote to existing Heroku repo
```
$ heroku git:remote -a moonbear
```
set git remote heroku to https://git.heroku.com/moonbear.git----Git remote named “heroku”

To list your existing app’s add-ons, run:
```
$ heroku addons --remote heroku
```
![](https://i.imgur.com/yLj02iM.png)

For each of the add-ons listed, create a corresponding counterpart on your test app:
```
$ heroku addons:create --remote heroku-20 papertrail 
```

do the same command to redis and postgresql
(also can do this addon with GUI)

For any config var present on your existing app that isn’t yet set on your test app, set it on the test app:
```
$ heroku config:set --remote heroku-20 <name>=<value>
```
(also can do this config set with GUI)

## step 3 Deploying the test app

Push the source to the test app’s remote:
```
$ git push heroku-20 master
```

Once the app is deployed, you should verify that it is working correctly, and if not, make any required changes or open a support ticket with the stack name in the subject line.
## step 4 Run your migrations on Heroku
```
$ heroku run rake db:migrate
$ heroku restart
```
Open your web app
```
$ heroku open
```

###### ref
https://devcenter.heroku.com/articles/upgrading-to-the-latest-stack#testing-an-app-on-a-new-stack
