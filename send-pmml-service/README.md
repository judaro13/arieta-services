## About

This service work with the data sent in the body, is needed two values
analytic_path => point to the analytic servie (openscoring)
analytic_data => pmml data

```
require 'net/http'
require 'uri'
require 'json'
uri = URI.parse("http://localhost:9292")
request = Net::HTTP::Post.new(uri)
request.content_type = "application/json"

pmml = File.read("single_iris_dectree.pmml").delete("\r\n")
data = {analytic_path:  "http://localhost:8080/openscoring/model/DecisionTreeIris",
analytic_data: pmml }
request.body = JSON.dump(data)

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end
```

## How to run

```
docker build -t judaro13/pmml-service .

docker run -d -p 9292:3000 judaro13/pmml-service  
```

Execute post to https://localhost:3000/


docker container ls
docker stop conatiner id
