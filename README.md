# ai-verify for kubernetes

## Docker Image Changes
The default docker image needs to be modified in order to run in kuberenetes.

We copy over the new run.sh to accomplish the following
- Remove ssl arguments from the `ng serve` command
- add the `--disable-host-check` argument to the `ng serve` command

Run the following commands to build and push the correct docker image:
```
cd docker
docker build -t <repo-name>/<image-name>:latest .
docker push <repo-or-user-name>/<image-name>:latest
```

## Kubernetes Manifests
The kubernetes manifests all live in the `kubernetes` directory.

After you have modified the appropriate files below, deploy by running:
```
cd kubernetes
kubectl apply -k .
```

We will use a kubectl tool called kustomize to deploy the files. There are the
following components that make up the app deployment.

### patch-deployment.yaml <-Modify Me
The only line you should have to change here is the image line. Make sure it
points to the image you built and push in the steps above

### patch-ingress.yaml <- Modify Me
Make sure to modify the url (hosts) lines. This will need to have a url that
the ingress controller on the kubernetes cluster is configured to resolve. If
your cluster leverages cert-manager or some other cert management system make
sure the annotations and tls sections are configured appropriately, otherwise
you will most likely need to remove those sections.


**Do not modify any remaing files**
### kustomization.yaml
This will tell `kubectl` where the core manifests are as well as where the
patch files live

### namespace.yaml
This simply creates the namespace where the deployment and all
other components will live.

### deployment.yaml
This is where we define important pod  information such as what container image
to use and any ports the image listen in on.

### service.yaml
This will create the connective tissue between the ingress object (dns entry)
and the main deployment pod

### ingress.yaml
This is where we define what url we will use as well as any information about
generating tls certs for the url

## Other notes
I generated all the default manifest files as a starting place running the
following commands:
```
kubectl create namespace ai-verify --dry-run=client --output=yaml > namespace.yaml
kubectl create deployment ai-verify --image=harbor.web.craigcloud.io/cnvrg/ai-verify-custom:latest --port=4200 --dry-run=client --output=yaml --namespace=ai-verify > deployment.yaml
kubectl expose deployment ai-verify --type=ClusterIP --port=4200 --name=ai-verify --namespace=ai-verify --dry-run=client --output=yaml > service.yaml
kubectl create ingress ai-verify --class=contour --rule="ai-verify.web.craigcloud.io/*=ai-verify:4200,tls=ai-verify" --annotation="cert-manager.io/cluster-issuer=letsencrypt-prod" --annotation="ingress.kubernetes.io/force-ssl-redirect=true" --annotation="kubernetes.io/tls-acme=true" --dry-run=client -n ai-verify -o yaml > ingress.yaml
```
I noticed that this container is running:
- redis
- mongodb
- ai-verify
It is basically a full app unto itself, this is a good reason why cnvrg would
not be a great target to run this. It really should be broken apart into three
different kubernetes deployments (redis/mongo/ai-verify). This would allow you
to create persistence for the mongo and redis pieces to allow ai-verify to die
and restart without losing any progress!
