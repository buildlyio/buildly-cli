# Buildly CLI Documentation

Welcome to the Buildly CLI - your comprehensive toolkit for building modern, scalable applications with microservices architecture, AI integration, and cloud-native deployment.

## 🚀 Quick Start

New to Buildly? Start here:

**[👉 Getting Started Guide](./getting-started.md)**

Follow our step-by-step tutorial to build your first AI-powered microservice application in 30 minutes.

## 📚 Documentation

### Core Guides

| Guide | Description | Time Required |
|-------|-------------|---------------|
| **[Getting Started](./getting-started.md)** | Build your first app from scratch | 30-45 min |
| **[Environment Setup](./environment-setup.md)** | Configure development environment | 15-30 min |
| **[Service Development](./service-development.md)** | Create microservices with AI | 20-40 min |
| **[AI Integration](./ai-integration.md)** | Add BabbleBeaver AI capabilities | 15-25 min |
| **[Deployment Guide](./deployment.md)** | Deploy to production | 30-60 min |
| **[Quick Reference](./quick-reference.md)** | Commands and troubleshooting | 5 min |

### What You Can Build

With Buildly CLI, you can create:

- **🏢 Enterprise Applications** - Customer management, inventory, HR systems
- **🛒 E-commerce Platforms** - Product catalogs, order processing, payment systems  
- **📱 SaaS Applications** - Multi-tenant platforms with user management
- **🤖 AI-Powered Apps** - Chatbots, content generation, predictive analytics
- **📊 Data Platforms** - Analytics dashboards, reporting systems
- **🔗 API Ecosystems** - Microservices with service discovery and routing

## 🏗️ Architecture Overview

Buildly uses a modern microservices architecture:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Buildly Core  │    │  Microservices  │
│  (React App)    │◄──►│   (Gateway)     │◄──►│   (Django)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  BabbleBeaver   │    │   Kubernetes    │    │    Database     │
│  (AI/LLM)       │    │   (Minikube)    │    │   (PostgreSQL)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Key Components

**🎯 Buildly Core**
- API Gateway and service discovery
- Authentication and authorization  
- Request routing and load balancing
- Service health monitoring

**🐍 Microservices**
- AI-generated Django applications
- RESTful APIs with auto-documentation
- Individual databases per service
- Docker containerized deployment

**🤖 BabbleBeaver AI Framework**
- LLM integration (OpenAI, Gemini)
- AI-powered code generation
- Intelligent data processing
- Chatbot and automation capabilities

**⚛️ Frontend Template**
- React-based single-page application
- Pre-configured API integration
- Modern UI components
- Responsive design

## 🛠️ CLI Commands

### Main Commands

| Command | Description |
|---------|-------------|
| `source dev.sh` | Launch main development menu |
| `./django.sh` | Generate AI-powered Django microservices |
| `./init.sh` | Initialize project configuration |

### Development Menu Options

When you run `source dev.sh`, you get these options:

1. **Set up Minikube** - Install and configure Kubernetes
2. **Set up Helm** - Install Helm package manager
3. **Set up Buildly Core** - Deploy the main backend framework
4. **Set up Buildly Template** - Install React frontend template  
5. **Set up Services** - Build and deploy custom services
6. **List Buildly Marketplace Services** - Browse available services
7. **Clone a Buildly Marketplace Service** - Add marketplace service
8. **Set up BabbleBeaver AI Framework** - Configure AI capabilities
9. **Exit** - Exit the CLI

## 🤖 AI-Powered Features

### Code Generation
- **Smart Models**: Describe your app, get Django models
- **REST APIs**: Auto-generated serializers and viewsets
- **Documentation**: Swagger/OpenAPI docs created automatically
- **Tests**: Basic test structure included

### Runtime AI Capabilities  
- **Natural Language Search**: Query your data conversationally
- **Content Generation**: Auto-create emails, descriptions, summaries
- **Sentiment Analysis**: Analyze customer feedback and reviews
- **Predictive Insights**: AI-powered business intelligence

### Example AI Workflow

```bash
# 1. Describe your service
"A customer management system for e-commerce with order tracking"

# 2. AI generates models
✅ Customer (profile, contact info)
✅ Order (items, status, tracking)  
✅ Address (shipping, billing)
✅ Preference (notifications, categories)

# 3. Full API automatically created
GET /api/customers/
POST /api/customers/
GET /api/orders/
# ... and more
```

## 📦 What Gets Generated

When you create a service, the CLI generates:

```
your-service/
├── 📄 Dockerfile                 # Container configuration
├── 🐳 docker-compose.yml        # Local development setup  
├── 📋 requirements.txt          # Python dependencies
├── ⚙️ manage.py                 # Django management
├── 📖 README.md                 # AI-generated docs
├── 🧩 logic_service/            # Main Django app
│   ├── 🗃️ models.py             # AI-generated models
│   ├── 🔄 serializers.py        # API serializers
│   ├── 🌐 views.py              # API endpoints  
│   ├── 🛣️ urls.py               # URL routing
│   ├── ⚡ admin.py              # Django admin
│   └── 📂 migrations/           # Database migrations
└── ⚙️ config/                   # Project settings
    ├── settings.py
    ├── urls.py
    └── wsgi.py
```

## 🌟 Key Features

### ✨ Rapid Development
- **Zero Configuration**: Works out of the box
- **AI Code Generation**: Describe what you want, get working code
- **Auto-deployment**: Services automatically deployed and connected
- **Hot Reload**: Changes reflected immediately

### 🔧 Production Ready
- **Kubernetes Native**: Built for cloud-native deployment
- **Scalable Architecture**: Microservices scale independently  
- **Security Built-in**: Authentication, authorization, input validation
- **Monitoring**: Health checks, logging, metrics included

### 🤖 AI-First
- **Multiple LLM Support**: OpenAI, Gemini, and more
- **Context Awareness**: AI understands your business domain
- **Code Quality**: AI generates production-ready code
- **Continuous Learning**: AI improves with usage

### 🛒 Marketplace Integration
- **Pre-built Services**: Authentication, payments, notifications
- **Community Contributions**: Shared services and templates
- **Easy Integration**: One-command service addition
- **Extensible**: Customize marketplace services

## 💡 Use Cases

### 🏢 Enterprise Applications

**Customer Management System**
```bash
./django.sh
# Service: customer-management  
# Description: "CRM with contact management, interaction history, and sales pipeline"
# Result: Complete CRM with AI insights
```

**Inventory Management** 
```bash  
./django.sh
# Service: inventory-system
# Description: "Track products, stock levels, suppliers, and automated reordering"
# Result: Smart inventory with predictive restocking
```

### 🛒 E-commerce Platform

**Product Catalog**
```bash
./django.sh  
# Service: product-catalog
# Description: "Product listings with categories, reviews, and recommendations"
# Result: AI-powered product discovery
```

**Order Management**
```bash
./django.sh
# Service: order-processing  
# Description: "Handle orders, payments, shipping, and customer notifications"
# Result: Complete order lifecycle management
```

### 📊 Data & Analytics

**Business Intelligence**
```bash
./django.sh
# Service: analytics-dashboard
# Description: "Customer behavior analysis, sales reporting, and predictive insights"  
# Result: AI-powered business intelligence
```

## 🚀 Deployment Options

| Environment | Use Case | Setup Time | 
|-------------|----------|------------|
| **Docker** | Local development, quick testing | 5 minutes |
| **Minikube** | Local Kubernetes, production simulation | 15 minutes |
| **AWS EKS** | Production cloud deployment | 30 minutes |
| **Google GKE** | Production cloud deployment | 30 minutes |
| **Azure AKS** | Production cloud deployment | 30 minutes |

## 🔍 Quick Commands Reference

### Environment Management
```bash
# Start development environment
source dev.sh

# Check Kubernetes status  
kubectl get pods --all-namespaces

# Check Docker containers
docker ps

# View service logs
docker-compose logs -f
```

### Service Management  
```bash
# Create new service
./django.sh

# List running services
kubectl get services

# Scale service
kubectl scale deployment customer-service --replicas=3

# Update service
kubectl set image deployment/customer-service app=customer-service:v2
```

### Troubleshooting
```bash
# Reset Minikube
minikube delete && minikube start

# Rebuild service  
docker-compose build --no-cache

# Check service health
curl http://localhost:8000/health/

# View detailed logs
kubectl logs -f deployment/customer-service
```

## 📞 Support & Community

### Getting Help

- **📖 Documentation**: Comprehensive guides and tutorials
- **🤝 Community Discord**: Join our developer community  
- **🐛 GitHub Issues**: Report bugs and request features
- **💼 Professional Support**: Enterprise support available

### Contributing

- **🔧 CLI Improvements**: Submit PRs for CLI enhancements
- **📝 Documentation**: Help improve our guides  
- **🛒 Marketplace**: Share your services with the community
- **🤖 AI Models**: Contribute to BabbleBeaver framework

### Links

- **Website**: [buildly.io](https://buildly.io)
- **GitHub**: [github.com/buildlyio](https://github.com/buildlyio)
- **Discord**: [discord.gg/buildly](https://discord.gg/buildly)  
- **Twitter**: [@buildlyio](https://twitter.com/buildlyio)

---

## 🎯 Next Steps

1. **[👉 Start Building](./getting-started.md)** - Follow our 30-minute tutorial
2. **[🔧 Set up Environment](./environment-setup.md)** - Configure your development setup  
3. **[🤖 Add AI Features](./ai-integration.md)** - Integrate BabbleBeaver AI framework
4. **[🚀 Deploy to Production](./deployment.md)** - Launch your application

**Ready to build the future?** [Get started now!](./getting-started.md) 🚀
