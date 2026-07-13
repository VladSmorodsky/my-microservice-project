#!/bin/bash
# Create ECR credentials secret for Jenkins/Kaniko

set -e

AWS_ACCOUNT_ID=590183992909
AWS_REGION="us-east-1"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "🔐 Creating ECR credentials secret..."
echo "Registry: ${ECR_REGISTRY}"

# Get ECR password
echo "📥 Getting ECR login password..."
ECR_PASSWORD=$(aws ecr get-login-password --region ${AWS_REGION})

# Create auth string
AUTH_STRING=$(echo -n "AWS:${ECR_PASSWORD}" | base64)

# Create config.json
echo "📝 Creating config.json..."
cat > /tmp/ecr-config.json <<EOF
{
  "auths": {
    "${ECR_REGISTRY}": {
      "auth": "${AUTH_STRING}"
    }
  }
}
EOF

# Create or update Kubernetes secret
echo "☸️  Creating Kubernetes secret in jenkins namespace..."
kubectl create secret generic aws-ecr-credentials \
  --from-file=config.json=/tmp/ecr-config.json \
  --namespace=jenkins \
  --dry-run=client -o yaml | kubectl apply -f -

# Cleanup
rm /tmp/ecr-config.json

echo ""
echo "✅ ECR credentials secret created successfully!"
echo ""
echo "Verify:"
echo "  kubectl get secret aws-ecr-credentials -n jenkins"
