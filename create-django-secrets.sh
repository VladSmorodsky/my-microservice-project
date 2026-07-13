#!/bin/bash
# Create Django secrets in Kubernetes (managed OUTSIDE Helm/ArgoCD)
# This secret persists independently of ArgoCD sync operations

set -e

NAMESPACE="${NAMESPACE:-default}"
SECRET_NAME="django-app-django-app-secret"

echo "🔐 Creating Django secrets..."
echo "Namespace: $NAMESPACE"
echo "Secret name: $SECRET_NAME"
echo ""

# Generate SECRET_KEY if not provided
if [ -z "$SECRET_KEY" ]; then
  echo "Generating new SECRET_KEY..."
  SECRET_KEY=$(python3 -c "from secrets import token_urlsafe; print(token_urlsafe(50))" 2>/dev/null || \
               openssl rand -base64 50 | tr -d '\n' | head -c 50)
  echo "✅ Generated new SECRET_KEY"
else
  echo "✅ Using provided SECRET_KEY from environment"
fi

# Use provided or default DATABASE_PASSWORD
if [ -z "$DATABASE_PASSWORD" ]; then
  DATABASE_PASSWORD="change-me-in-production"
  echo "⚠️  Using default DATABASE_PASSWORD (change it!)"
else
  echo "✅ Using provided DATABASE_PASSWORD from environment"
fi

echo ""
echo "Creating Secret in Kubernetes..."

# Create temporary manifest with ArgoCD ignore annotations
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
  annotations:
    # Tell ArgoCD to not manage this Secret
    argocd.argoproj.io/compare-options: "IgnoreExtraneous"
    argocd.argoproj.io/sync-options: "Prune=false"
type: Opaque
stringData:
  SECRET_KEY: "$SECRET_KEY"
  DATABASE_PASSWORD: "$DATABASE_PASSWORD"
EOF

echo ""
echo "✅ Django secrets created successfully!"
echo ""
echo "📊 Summary:"
echo "  Namespace: $NAMESPACE"
echo "  Secret: $SECRET_NAME"
echo "  Keys: SECRET_KEY (${#SECRET_KEY} chars), DATABASE_PASSWORD"
echo ""
echo "🔍 Verify:"
echo "  kubectl get secret $SECRET_NAME -n $NAMESPACE"
echo "  kubectl describe secret $SECRET_NAME -n $NAMESPACE"
echo ""
echo "⚠️  IMPORTANT:"
echo "  - Secret is NOT stored in Git"
echo "  - Secret is encrypted at rest in etcd"
echo "  - ArgoCD will NOT delete or modify this Secret"
echo "  - To rotate: delete and re-run this script"
echo ""
echo "💾 To save for backup (optional, keep secure!):"
echo "  cat > .env.secrets <<EOF"
echo "SECRET_KEY=$SECRET_KEY"
echo "DATABASE_PASSWORD=$DATABASE_PASSWORD"
echo "EOF"
echo "  chmod 600 .env.secrets"
echo "  # Add .env.secrets to .gitignore!"
