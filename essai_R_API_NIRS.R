

library(httr)
library(jsonlite)
response <- POST(url = "http://moleans.cirad.fr:8080/nirs_api/login", query = list("user"="test", "password"="test"))

json = fromJSON(rawToChar(response$content))
token <- json$token
t <- paste("Bearer", token)


print(json)


response <- GET(url = "http://moleans.cirad.fr:8080/nirs_api/spectra", add_headers("Authorization"=t), query = list("type"="spectrum"))
response <- GET(url = "http://moleans.cirad.fr:8080/nirs_api/spectra/3", add_headers("Authorization"=t))

json = fromJSON(rawToChar(response$content))
print(json)
