# cluster-gitops with NKP Pro

The objective of this project is to provide guidance on using gitops to manage NKP Management Cluster resources like:
- Workspaces & Workspace RBAC
- Clusters

Simply apply the following manifest to apply this to the cluster.
> Note: Make changes to the workspacs, projects, rbac and clusters to be created as required
> For clusters it is assumed that any secrets with PC credentials or Registry Credentials will be applied directly in the given workspace namespace of the Management Cluster. Sample secrets are provided within resources/workspaces/lazarus/cluster with yaml.example files
```
kubectl apply -f -  <<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: lazarus-gitops
  namespace: kommander
spec:
  interval:  5s
  ref:
    branch: main
  timeout: 20s
  url: https://github.com/WinsonSou/lazarus-cluster-gitops-pro.git
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: lazarus-gitops
  namespace: kommander
spec:
  interval: 5s
  path: ./
  prune: true
  sourceRef:
   kind: GitRepository
   name: lazarus-gitops
   namespace: kommander
EOF


```

