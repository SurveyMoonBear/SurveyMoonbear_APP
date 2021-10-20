# pgAdmin Remote Connection (Heroku) 
## pgAdmin Remote Connection
### Step1: Download pgAdmin from official website 
[PostgreSQL: Downloads](https://www.postgresql.org/download/)
### Step2: Get Postgres credentials
* Method1: Check Postgres url in heroku config vars
`postgres://<user_name>:<password>@<host_name>:<port>/<db_name>`
* Method2: Get from heroku comend
```
$ heroku pg:credentials:url HEROKU_POSTGRESQL_AQUA_URL
```

### Step3: Using pgAdmin GUI to connect remote server
* Right click on **Servers** → **Create**→ **Server**
![](https://i.imgur.com/Y224spx.png)

* **General**: Name whatever you want
![](https://i.imgur.com/kFpZDxT.png)

* **Connection**: Fill with credentials
![](https://i.imgur.com/hRFToiA.png)

* **SSL**: set SSL mode to ‘Require’
![](https://i.imgur.com/YHoRlvx.png)

* **Advance**: Restrict DBs to the DBs you care (or it will list tons of DBs that you don’t have permission)
![](https://i.imgur.com/QehUtNq.png)


## View/Edit data in pgAdmin

Schemas-public-Tables: Right-click on the table
![](https://i.imgur.com/meuPDcx.png)

