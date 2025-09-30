# Quick Reference Guide

Fast reference for common Buildly CLI commands, troubleshooting, and workflows.

## 🚀 Essential Commands

### Initial Setup
```bash
# Clone and setup CLI
git clone https://github.com/buildlyio/buildly-cli.git
cd buildly-cli
chmod +x *.sh

# Start main menu
source dev.sh

# Create new service
./django.sh
```

### Environment Management
```bash
# Check Kubernetes status
kubectl get pods --all-namespaces
kubectl get services
kubectl get deployments

# Check Docker containers  
docker ps
docker images
docker-compose ps

# Minikube operations
minikube status
minikube start
minikube stop
minikube delete
minikube dashboard
```

### Service Operations
```bash
# Start/stop services
docker-compose up -d
docker-compose down
docker-compose restart

# View logs
docker-compose logs -f
docker-compose logs service-name
kubectl logs -f deployment/service-name

# Scale services
kubectl scale deployment service-name --replicas=3

# Update service image
kubectl set image deployment/service-name container=image:tag
```

## 🔧 Development Workflow

### 1. Environment Setup (One-time)
```bash
source dev.sh
# 1. Set up Minikube
# 2. Set up Helm  
# 3. Set up Buildly Core
# 4. Set up Buildly Template (optional)
# 8. Set up BabbleBeaver AI (optional)
```

### 2. Create Service  
```bash
./django.sh
# Enter service name: my-service
# Describe what it does
# Let AI generate models
# Choose project location
```

### 3. Test & Iterate
```bash
# Test API
curl http://localhost:8000/api/docs/

# View frontend  
open http://localhost:3000

# Check health
curl http://localhost:8000/health/
```

## 📊 Service Endpoints

### Standard API Endpoints (Auto-generated)
```bash
# List all items
GET /api/model-name/

# Create new item
POST /api/model-name/
Content-Type: application/json
{
  "field1": "value1",
  "field2": "value2"
}

# Get specific item
GET /api/model-name/{id}/

# Update item
PUT /api/model-name/{id}/
PATCH /api/model-name/{id}/

# Delete item  
DELETE /api/model-name/{id}/

# API documentation
GET /api/docs/
GET /api/redoc/

# Health check
GET /health/
```

### Common Query Parameters
```bash
# Search
GET /api/customers/?search=john

# Filtering
GET /api/customers/?is_active=true
GET /api/orders/?status=completed

# Ordering
GET /api/customers/?ordering=created_at
GET /api/customers/?ordering=-created_at

# Pagination
GET /api/customers/?page=2&page_size=10
```

## 🐛 Troubleshooting

### Common Issues & Solutions

#### Minikube Won't Start
```bash
# Problem: Minikube fails to start
# Solution 1: Reset Minikube
minikube delete
minikube start

# Solution 2: Use different driver
minikube start --driver=docker
minikube start --driver=virtualbox

# Solution 3: Increase resources
minikube start --memory=8192 --cpus=4
```

#### Port Already in Use
```bash
# Problem: Port 8000/3000/8080 already in use
# Check what's using the port
lsof -i :8000
lsof -i :3000  
lsof -i :8080

# Kill process using port
kill -9 <PID>

# Or use different port
docker-compose up -d -p 8001:8000
```

#### Docker Issues
```bash
# Problem: Docker containers won't start
# Check Docker is running
docker --version
docker ps

# Restart Docker daemon (Linux)
sudo systemctl restart docker

# Reset Docker environment for Minikube
eval $(minikube docker-env)

# Clean up Docker
docker system prune -a
```

#### Service Won't Build
```bash
# Problem: Service fails to build/start
# Check logs
docker-compose logs service-name

# Rebuild without cache
docker-compose build --no-cache
docker-compose up --force-recreate

# Check dependencies
docker-compose exec service-name pip list
```

#### Permission Errors
```bash
# Problem: Permission denied errors
# Fix script permissions
chmod +x *.sh

# Fix file ownership
sudo chown -R $USER:$USER ./project-directory

# Fix Docker permissions (Linux)
sudo usermod -aG docker $USER
newgrp docker
```

#### AI/Ollama Issues
```bash
# Problem: AI model not working
# Check Ollama status
ollama --version
ollama list

# Pull model manually
ollama pull deepseek-coder-v2

# Check model file location
ls -la *.modelfile

# Restart Ollama service
brew services restart ollama
```

## 🔍 Debugging Commands

### Inspect Services
```bash
# Kubernetes debugging
kubectl describe pod pod-name
kubectl describe deployment deployment-name  
kubectl describe service service-name

# Get into running container
kubectl exec -it pod-name -- /bin/bash
docker-compose exec service-name bash

# Check resource usage
kubectl top pods
kubectl top nodes
docker stats
```

### Network Debugging  
```bash
# Check service connectivity
kubectl port-forward service/service-name 8000:8000
curl http://localhost:8000/health/

# Check cluster networking
kubectl get endpoints
kubectl get ingress

# Minikube IP and services
minikube ip
minikube service list
minikube service service-name --url
```

### Database Debugging
```bash
# Connect to PostgreSQL
docker-compose exec db psql -U username -d database_name

# Check database connection
docker-compose exec service-name python manage.py dbshell

# Run migrations
docker-compose exec service-name python manage.py migrate

# Check migration status  
docker-compose exec service-name python manage.py showmigrations
```

## 📝 Configuration Files

### Key Files to Know

```bash
# CLI scripts
dev.sh                    # Main development menu
django.sh                 # Service generator  
init.sh                   # Project initialization

# Generated service files
docker-compose.yml        # Local development setup
Dockerfile               # Container configuration
requirements.txt         # Python dependencies
manage.py               # Django management
config/settings.py      # Django settings

# Kubernetes files  
k8s/deployment.yaml     # Kubernetes deployment
k8s/service.yaml        # Kubernetes service  
k8s/ingress.yaml        # Kubernetes ingress

# AI configuration
BabbleBeaver/config/openai.yaml   # OpenAI settings
BabbleBeaver/config/gemini.yaml   # Gemini settings
*.modelfile                       # Ollama model configs
```

### Common Configuration Changes

#### Database Settings
```python
# config/settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'your_database',
        'USER': 'your_user', 
        'PASSWORD': 'your_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

#### Docker Environment
```yaml
# docker-compose.yml
environment:
  - DEBUG=True
  - DATABASE_URL=postgresql://user:pass@db:5432/dbname
  - CORS_ALLOWED_ORIGINS=http://localhost:3000
```

#### Kubernetes Resources
```yaml
# k8s/deployment.yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi" 
    cpu: "500m"
```

## 🎯 Performance Tips

### Development Performance
```bash
# Use Docker BuildKit for faster builds
export DOCKER_BUILDKIT=1
docker-compose build

# Increase Minikube resources  
minikube config set memory 8192
minikube config set cpus 4

# Enable Kubernetes dashboard
minikube addons enable dashboard
minikube addons enable metrics-server
```

### Service Optimization
```python
# Enable Django caching
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': 'redis://redis:6379/1',
    }
}

# Database connection pooling
DATABASES['default']['CONN_MAX_AGE'] = 60
```

## 📱 Mobile/API Testing

### Using curl
```bash
# Test authentication
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# Use token in requests
curl -H "Authorization: Token your-token-here" \
  http://localhost:8000/api/customers/
```

### Using HTTPie (Alternative to curl)
```bash
# Install HTTPie
pip install httpie

# Make requests
http POST localhost:8000/api/customers/ first_name=John last_name=Doe
http GET localhost:8000/api/customers/ search==john
```

## 🔄 Backup & Restore

### Database Backup
```bash
# Backup PostgreSQL
docker-compose exec db pg_dump -U username database_name > backup.sql

# Restore PostgreSQL  
docker-compose exec -T db psql -U username database_name < backup.sql
```

### Full Service Backup
```bash
# Backup service code and data
tar -czf service-backup.tar.gz service-directory/

# Backup Kubernetes configs
kubectl get all -o yaml > k8s-backup.yaml
```

## 🚀 Deployment Shortcuts

### Local Development
```bash
# Quick local setup
source dev.sh && echo "1\n2\n3" | source dev.sh
./django.sh
```

### Production Deploy
```bash
# Build and push images
docker build -t registry.com/service:v1.0.0 .
docker push registry.com/service:v1.0.0

# Deploy to Kubernetes
kubectl set image deployment/service service=registry.com/service:v1.0.0
kubectl rollout status deployment/service
```

## 📞 Getting Help

### Log Locations
```bash
# Docker Compose logs
docker-compose logs service-name

# Kubernetes logs  
kubectl logs -f deployment/service-name
kubectl logs -f pod/pod-name

# Minikube logs
minikube logs

# System logs (Linux)
journalctl -u docker
journalctl -u kubelet
```

### Health Checks
```bash
# Service health
curl http://localhost:8000/health/

# Kubernetes health
kubectl get componentstatuses
kubectl cluster-info

# Docker health
docker system df
docker system events
```

### Support Resources
- **Documentation**: All guides in `docs/` directory
- **GitHub Issues**: Report bugs and get help
- **Discord Community**: Real-time support chat
- **Stack Overflow**: Tag questions with `buildly`

---

**💡 Pro Tip**: Bookmark this page for quick reference during development!