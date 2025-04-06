# cluster-gitops with NKP Pro

The objective of this project is to provide guidance on using gitops to manage NKP Management Cluster resources like:
- Workspaces & Workspace RBAC
- Clusters

## Repository Structure

```mermaid
graph TD
    %% Root directory
    Root["/"] --> Kustomizations["kustomizations/"]
    Root --> Resources["resources/"]
    Root --> RootKustYaml["kustomization.yaml"]
    Root --> WorkspaceKustYaml["workspace-kustomization.yaml"]
    Root --> ClustersKustYaml["clusters-kustomization.yaml"]
    
    %% Root kustomization file references
    RootKustYaml -- "resources:" --> WorkspaceKustYaml
    RootKustYaml -- "resources:" --> ClustersKustYaml
    
    %% Kustomizations directory
    Kustomizations --> KustWork["workspaces/"]
    Kustomizations --> KustCluster["clusters/"]
    
    %% Kustomization files in subdirectories
    KustWork --> KWorkKustYaml["kustomization.yaml"]
    KustCluster --> KClusterKustYaml["kustomization.yaml"]
    
    %% Resources directory
    Resources --> ResWorkspaces["workspaces/"]
    
    %% Resources/workspaces directory
    ResWorkspaces --> ResWorkKustYaml["kustomization.yaml"]
    ResWorkspaces --> Lazarus["lazarus/"]
    ResWorkspaces --> Phoenix["phoenix/"]
    
    %% Lazarus directory
    Lazarus --> LazWorkspace["lazarus-workspace.yaml"]
    Lazarus --> LazCluster["cluster/"]
    
    %% References from kustomization files to resources
    KWorkKustYaml -- "resources:\n../../resources/workspaces" --> ResWorkspaces
    KClusterKustYaml -- "resources:\n../../resources/workspaces/lazarus/cluster" --> LazCluster
    
    %% Flux Kustomization references
    WorkspaceKustYaml -- "path: ./kustomizations/workspaces" --> KustWork
    ClustersKustYaml -- "path: ./kustomizations/clusters" --> KustCluster
    
    %% Dependencies
    ClustersKustYaml -. "dependsOn:\n- name: lazarus-workspace" .-> WorkspaceKustYaml
    
    %% Subgraph for legend
    subgraph Legend
        Dir["Directory"]
        KustFile["Kustomization File"]
        ResFile["Resource File"]
        RefArrow["Reference"]
        DepArrow["Dependency"]
    end
    
    %% Styling
    classDef directory fill:#dfd,stroke:#333,stroke-width:1px
    classDef kustomization fill:#f9f,stroke:#333,stroke-width:2px
    classDef resource fill:#bbf,stroke:#333,stroke-width:1px
    classDef reference stroke:#333,stroke-width:1px
    classDef dependency stroke-dasharray: 5 5
    
    %% Assign classes
    class Root,Kustomizations,Resources,KustWork,KustCluster,ResWorkspaces,Lazarus,Phoenix,LazCluster directory
    class RootKustYaml,WorkspaceKustYaml,ClustersKustYaml,KWorkKustYaml,KClusterKustYaml,ResWorkKustYaml kustomization
    class LazWorkspace resource
    class Dir directory
    class KustFile kustomization
    class ResFile resource
    class RefArrow reference
    class DepArrow dependency
```

The diagram above illustrates the relationships between files and directories in this GitOps repository:

- **Pink boxes**: Kustomization files
- **Green boxes**: Directories
- **Blue boxes**: Resource files
- **Solid arrows**: References between files (e.g., one file includes another)
- **Dashed arrows**: Dependencies (e.g., one kustomization depends on another)

The repository follows a layered approach:
1. Root level kustomization.yaml points to workspace and clusters kustomizations
2. Workspace kustomization sets up workspaces first
3. Clusters kustomization depends on workspace kustomization
4. Resources are organized by workspace

Apply the following manifest to apply this to the Management Cluster.
> Note: Make changes to the workspacs, projects, rbac and clusters to be created as required

> For clusters it is assumed that any secrets with PC credentials or Registry Credentials will be applied directly in the given workspace namespace of the Management Cluster. 

> This repository uses sealed secrets. Find out more about sealed secrets at https://fluxcd.io/flux/guides/sealed-secrets/ and https://github.com/bitnami-labs/sealed-secrets

> You will need to create your own sealed secrets to use this repo. the .sh files in the resources/workspaces/lazarus/cluster shows you how to create these sealed secrets.

```
#Add SealedSecrets HelmRepo
kubectl apply -f -  <<EOF
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: sealed-secrets
  namespace: kommander
spec:
  interval: 1h0m0s
  url: https://bitnami-labs.github.io/sealed-secrets
---
#Install SealedSecrets via HelmRelease
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: sealed-secrets
  namespace: kommander
spec:
  chart:
    spec:
      chart: sealed-secrets
      sourceRef:
        kind: HelmRepository
        name: sealed-secrets
      version: ">=1.15.0-0"
  interval: 1h0m0s
  releaseName: sealed-secrets-controller
  targetNamespace: kube-system
  install:
    crds: Create
  upgrade:
    crds: CreateReplace
---
#Add Git Repo to point to Cluster GitOps Source
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
#Configure FluxCD kustomize
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
