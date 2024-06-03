#!/bin/bash

# kubectlのインストール
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# kubectlのインストールを確認
kubectl version --client | tee kubectl-install-log.txt

# ArgoCDのインストール
sudo kubectl create namespace argocd
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# ArgoCDサーバーをNodePortサービスとして設定
cat << 'EOF' > argocd-server-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/name: argocd-server
    app.kubernetes.io/part-of: argocd
  name: argocd-server-nodeport
  namespace: argocd
spec:
  ports:
  - name: http
    nodePort: 30007
    port: 80
    targetPort: 8080
  - name: https
    nodePort: 30008
    port: 443
    targetPort: 8080
  selector:
    app.kubernetes.io/name: argocd-server
  type: NodePort
EOF

sudo kubectl apply -f argocd-server-nodeport.yaml | tee argocd-install-log.txt

# 初期パスワードの取得
echo "Initial admin password:" | tee -a argocd-install-log.txt
sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d | tee -a argocd-install-log.txt; echo | tee -a argocd-install-log.txt

# ArgoCDアプリケーションマニフェストの作成
mkdir -p argo

cat << 'EOF' > argo/helm-techtrends-staging.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: techtrends-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/YourGithubUserName/YourRepository'
    targetRevision: HEAD
    path: helm/techtrends
    helm:
      valueFiles:
        - values-staging.yaml
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: staging
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

cat << 'EOF' > argo/helm-techtrends-prod.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: techtrends-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/YourGithubUserName/YourRepository'
    targetRevision: HEAD
    path: helm/techtrends
    helm:
      valueFiles:
        - values-prod.yaml
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# ArgoCDアプリケーションの適用
sudo kubectl apply -f argo/helm-techtrends-staging.yaml | tee -a argo/apply-log.txt
sudo kubectl apply -f argo/helm-techtrends-prod.yaml | tee -a argo/apply-log.txt

# ArgoCDアプリケーションの同期とリソース確認
sudo kubectl get applications -n argocd | tee -a argo/apply-log.txt
sudo kubectl get all -n staging | tee -a argo/apply-log.txt
sudo kubectl get all -n prod | tee -a argo/apply-log.txt

echo "ArgoCD setup and application deployment complete."
