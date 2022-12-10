# Trying Flux

Tiny lab for spike purpose about  [`Flux`](https://fluxcd.io/) 

---
***Prerequisites:***
1. [`docker`](https://www.docker.com/): docker daemon for containerization purpose
2. [`kubectl`](https://kubernetes.io/docs/tasks/tools/): docker cli
3. [`kind`](https://kind.sigs.k8s.io/)
4. [`Flux CLI`](https://fluxcd.io/flux/installation/#install-the-flux-cli)
5. [`yq`](https://github.com/mikefarah/yq)

---

#### Create a Personal access token on Github. more precisely [`here`](https://github.com/settings/tokens) and for this purpose select `repo` and `user` scope

![image-001](./diagrams_and_images/image_001.png) 

#### Once you have those, export `GITHUB_TOKEN` and `GITHUB_USER` with your own token and github user
```bash
export GITHUB_TOKEN=<your_token>
```

```bash
export GITHUB_USER=<your_username>
```

#### Spin up your kind cluster along with installing the testing application
```bash
make all
```

#### Create a github repository bound to flux via `flux bootstrap` command
```bash
flux bootstrap github \
--owner stefanoabalsamo79 \
--personal \
--private \
--repository trying-fluxcd-demo \
--path=clusters/kind
```

You will see the following output:
![image-003](./diagrams_and_images/image_003.png)

#### After flux bootstrap is done you can see that the demanded [`trying-flux-demo`](https://github.com/stefanoabalsamo79/trying-flux-demo.git) repository has been created along with some controller installed on your cluster
![image-004](./diagrams_and_images/image_004.png) 

![image-005](./diagrams_and_images/image_005.png)

You can tell that some CRD have been created to make flux working within the cluster along with `flux-system` namespace and `Kustomization` resource (if you don't know yet have a look [kustomize](https://kustomize.io/)) working with `GitRepository` CRD.

#### Clone the repository which have been created and have a look
```bash
git clone https://github.com/stefanoabalsamo79/trying-fluxcd-demo.git
```
![image-006](./diagrams_and_images/image_006.png)

#### So now let's define a `ServiceAccount` and `RoleBinding` within a file at `clusters/minikube/test/rbac.yaml` within `trying-flux-demo` repository

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    toolkit.fluxcd.io/tenant: test
  name: test
  namespace: test

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    toolkit.fluxcd.io/tenant: test
  name: test-reconciler
  namespace: test
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole 
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: gotk:test:reconciler
- kind: ServiceAccount
  name: test
  namespace: test

```

#### And then push those changes against the repository 
```bash
git add . &&  \
git commit -m "adding ns, svc acct and rolebinding" &&  \
git push origin main
```

#### Trigger flux reconciliation to prevent from waiting its next run which has been configured as 1 minute frequency (default)
```bash
flux reconcile ks flux-system --with-source
```

#### Setting you new sources (i.e. git and kustomization sync)
```bash
flux create source git trying-fluxcd-app \
--namespace=test \
--url=https://github.com/stefanoabalsamo79/trying-fluxcd \
--branch=master \
--export > /Users/stefanoabalsamo/MyProjects/trying-fluxcd-demo/clusters/kind/test/sync.yaml
```
```bash
flux create kustomization trying-fluxcd-app \
--namespace=test \
--source=GitRepository/trying-fluxcd-app \
--path="./app/kustomize" \
--export >> /Users/stefanoabalsamo/MyProjects/trying-fluxcd-demo/clusters/kind/test/sync.yaml
```

#### Have a look at `clusters/minikube/test/sync.yaml` file you've just created before applying
```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: trying-fluxcd-app
  namespace: test
spec:
  interval: 1m0s
  ref:
    branch: master
  url: https://github.com/stefanoabalsamo79/trying-fluxcd

---
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: trying-fluxcd-app
  namespace: test
spec:
  interval: 1m0s
  path: ./app/kustomize # notice not the whole repository, just where the app's manifest are found
  prune: false
  sourceRef:
    kind: GitRepository
    name: trying-fluxcd-app
```

#### Now let's push these changes to `trying-flux-demo` repository and fire flux reconciliation again 
```bash
git add . &&  \
git commit -m "adding GitRepository and Kustomization for application sync" && \ 
git push origin main
```
```bash
flux reconcile ks flux-system --with-source
```

#### Test the app
```bash
curl http://localhost
```
***output:***
```json
{"message":"[1.0.0] Howdy, how is going? All good over here :-)"}
```

#### Now let's make some changes to the [`Deployment`](./app/kustomize/deployment.yaml), TEST_VAR env variable for instance so we can trigger the sync and tell that a new version is replying
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-flux-app-deployment
...
spec:
  ...
  template:
    ...
    spec:
      ...
          env:
          - name: TEST_VAR
            value: 1.0.1
```
### Push this changes to `trying-fluxcd` repository
```bash
git add . &&  \
git commit -m "changing TEST_VAR variable so the application will be synched " && \ 
git push origin master
```

#### Fire flux reconciliation again 
```bash
flux reconcile ks flux-system --with-source
```

#### Test the app again
```bash
curl http://localhost
```
***output:***
```json
{"message":"[1.0.1] Howdy, how is going? All good over here :-)"}
```

#### Some command I found useful
```bash
flux get source git -A
```

```bash
flux get ks -A
```





