# Cip 143 Offchain 

### How to Setup local Postgres for dev

Init local dev psql db

`createuser --superuser postgres`

`psql -U postgres`

Then create db:

```
CREATE USER cip143 PASSWORD 'password';

CREATE DATABASE cip143 WITH OWNER cip143;
```
