cat << EOF > lazarus-workload-pc-credentials-for-csi.yaml
apiVersion: v1
data:
  #base64 encoded secret in prismCentralIP:prismCentralPort:prismCentralUsername:prismCentralPassword
  key: MTEuMTEuMTEuMTE6OTQ0MDp0ZXN0OnRlc3QK
kind: Secret
metadata:
  labels:
    cluster.x-k8s.io/provider: nutanix
  name: lazarus-workload-pc-credentials-for-csi
  namespace: lazarus-workspace
type: Opaque
EOF

kubeseal --format yaml --scope cluster-wide < lazarus-workload-pc-credentials-for-csi.yaml > lazarus-workload-pc-credentials-for-csi-sealed.yaml
