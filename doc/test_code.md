# Run the tests
1. Migrate test.db
```
RACK_ENV=test bundle exec rake db:migrate
```
2. Run tests

- Run integration tests
```
rake spec
```

- Run no-cassetttes tests (SQS)
```
rake spec:novcr
```
