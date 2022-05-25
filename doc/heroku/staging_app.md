# Heroku staging app

1. Create a new heroku dyno name staging
    ```
    heroku create <appname-staging> --remote <staging>
    ```
2. Push master branch to remote git
    ```
    git push <staging> master
    ```
    Push other branch to remote git
    ```
    git push -f <staging> <branch name>:master
    ```
3. Check a Postgres server
    ```
    heroku pg:info --app <appname-staging>
    ```
    If no Postgres server, add it

    ```
    heroku addons:create heroku-postgresql --app <appname-staging>
    ```
4. Set ALL the config variables (following are just part of them)
    ```
    heroku config:set BUNDLE_WITHOUT=development:test --app <appname-staging>
    heroku config:set RACK_ENV=production --app <appname-staging>
    ```
5. DB migration
    ```
    heroku run rake db:migrate --app <appname-staging>
    ```

6. Restart & Open
    ```
    heroku restart --app <appname-staging>
    ```
    Open
    ```
    heroku open --app <appname-staging>
    ```
7. Check staging app status
    ```
    heroku ps --app <appname-staging>
    ```

## Note
1. Do we need to add the `staging` ENV setting?
2. If delete the staging app, check that removing the `git remote -v` or not.
    If git remove didn't remove, we can use the same staging app name and same git remote.
    Or to change staging app name and the git remote 
    ```
    git remote rm <staging>
    git remote add <staging> https://git.heroku.com/<newappname-staging>.git
    git push <staging> master
    ```
