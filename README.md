# Simple Pod for testing Openshift storage performance

## BUILD

```
make
```

## RUN

```
make run
```

## To Deploy manually 

as user:
```
oc login https://openshift-console.example.com
oc apply -f config/openshift/main/pvc.yaml
oc apply -f config/openshift/main/dc.yaml
```

## TEST
Browse to <app-url>/mnt 

in terminal check:
```
ls -al  /app/web/mnt
```

## or TEST LOCALLY
```
curl localhost:8080/
```
