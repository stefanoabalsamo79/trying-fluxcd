# test-flux-app
Simple node app in order to test flux

---
***Prerequisites:***
1. [`docker`](https://www.docker.com/): docker daemon for containerization purpose
2. [`kubectl`](https://kubernetes.io/docs/tasks/tools/): docker cli
3. [`minikube`](https://minikube.sigs.k8s.io/docs/): in order to apply against local [`kubernetes`](https://kubernetes.io/) environment
5. [`yq`](https://github.com/mikefarah/yq): [`yaml`](https://en.wikipedia.org/wiki/YAML) parser
6. [`jq`](https://stedolan.github.io/jq/download/): json parser


---


#### Kustomization detail

**kustomization.yaml**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: test
resources:
  - deployment.yaml
  - service.yaml
```

**deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-flux-app-deployment
  annotations:
    version: 1.0.0
spec:
  progressDeadlineSeconds: 600
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: test-flux-app
  replicas: 1
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: test-flux-app
    spec:
      securityContext: {}
      terminationGracePeriodSeconds: 30
      containers:
        - name: test-flux-app
          image: test-flux-app:1.0.0
          imagePullPolicy: IfNotPresent
          ports:
          - containerPort: 3000
            protocol: TCP
          resources:
            limits:
              cpu: 300m
              memory: 1G
            requests:
              cpu: 200m
              memory: 500M
```

**service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: test-flux-app-service
spec:
  type: ClusterIP
  selector:
    app: test-flux-app
  ports:
  - port: 3000
    protocol: TCP
    targetPort: 3000
    name: http
  sessionAffinity: None
```