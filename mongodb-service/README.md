## About

This images need a enviroment variable
``
db_path
``
with the path and port like "localhost:27017", where is located the Mongodb database.

Curl example
```
curl -H "Content-Type: application/json" -X POST -d '[{"a":"xyz","b":"xyz"},{"a":"xyz","b":"xyz"}]' http://localhost:301/miTabla
```

there is just one endpoint
```
GET /:miTableName
```
:miTableName indicate the table where will be stored the data sent.
The data must be have a json format.
The data must be an array of hashes.

## How to run

```
docker build -t judaro13/mongodb-service .

docker run --net="host" -p 9292:9292 -d -e "db_path=localhost:27017" judaro13/mongodb-service
```

docker container ls
Execute post to  with correct port https://localhost:3000/


docker stop conatiner id


{"db_path"=>"http://localhost:27017"}
