# How to Use

## Run bash file to install

```
bash install.sh
```

## To restart servers

```
docker-compose restart
```

## To stop servers

```
docker-compose stop
```

## To start servers

```
docker-compose start
```


## To remove clean servers

```
docker-compose down
```

When install again run ```docker-compose down``` to clean all docker container running and run install again ```bash install.sh```

# Install auto deoployment and github hook

- Install app hook service
```
  curl https://raw.githubusercontent.com/schickling/docker-hook/master/docker-hook > /usr/local/bin/docker-hook; chmod +x /usr/local/bin/docker-hook
```

- Run hook service at default port 8555 (you must allow port from firewall)
```
  docker-hook -t magestore-staging-deployment-token -c bash ./deployment.sh &
```

- Setup github hook url to http://130.211.114.4:8555/magestore-staging-deployment-token
