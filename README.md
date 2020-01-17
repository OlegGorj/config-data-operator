# Kubernetes Configuration operator

The operator designed to dynamically manage ConfigMaps for Kubernetes cluster, based on Config Data (config-data-service)

### Project status: in development

## Initialize GCP project and connect to Kubernetes cluster


To list all GCP projects you have access to:

```
$ gcloud projects list
PROJECT_ID                  NAME                        PROJECT_NUMBER
my_gcp_project              my_gcp_project              90002648334518
...
...

```

To select project, run:

```
$ gcloud config set project my_gcp_project
```

Login to GCP project:

```
$ gcloud auth login
```

_note: add instructions for k8s cluster deployment_

Get the credentials for your Kubernetes cluster (assuming you have one deployed)

```
$ gcloud container clusters get-credentials standard-cluster-1 --zone us-central1-a --project my_gcp_project
```


And, to test if you have access to Kubernetes cluster:

```
$ kubectl get nodes
NAME                                                STATUS   ROLES    AGE    VERSION
gke-standard-cluster-1-default-pool-b967307a-b2cz   Ready    <none>   3m2s   v1.13.7-gke.8
gke-standard-cluster-1-default-pool-b967307a-nxz6   Ready    <none>   3m3s   v1.13.7-gke.8
gke-standard-cluster-1-default-pool-b967307a-whc7   Ready    <none>   3m3s   v1.13.7-gke.8

```

## Deploy Config Operator

Clone operator repo:

```
https://github.com/OlegGorj/config-data-operator.git
cd config-data-operator
```

Deploy operator:
```
make deploy
```

Check if all ConfigMaps are there:
```
kubectl get configmaps
```


Clean up:

```
make deployclean
```
