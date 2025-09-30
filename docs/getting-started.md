# Getting Started with Buildly CLI

Welcome to Buildly CLI! This guide will walk you through your first experience building a complete application with AI-powered microservices, from installation to deployment.

## What You'll Build

By the end of this guide, you'll have:
- A working Buildly development environment
- A customer management microservice with AI-generated code
- A frontend React application
- Everything running on Kubernetes or Docker

**Time Required:** 30-45 minutes

## Prerequisites

Before we begin, make sure you have:

- **macOS or Linux** (Windows support via WSL2)
- **8GB+ RAM** (for running Kubernetes locally)
- **10GB+ free disk space** 
- **Internet connection** (for downloading dependencies)
- **Terminal/Command Line** access

## Step 1: Installation

### Clone the Buildly CLI

Open your terminal and run:

```bash
# Navigate to your projects directory
cd ~/Projects  # or wherever you keep your projects

# Clone the Buildly CLI
git clone https://github.com/buildlyio/buildly-cli.git
cd buildly-cli

# Make scripts executable
chmod +x *.sh

# Verify installation
ls -la *.sh
```

You should see:
```
-rwxr-xr-x  1 user  staff  dev.sh
-rwxr-xr-x  1 user  staff  django.sh  
-rwxr-xr-x  1 user  staff  init.sh
```

## Step 2: Environment Setup

### Launch the Buildly CLI

```bash
source dev.sh
```

You'll see Buster the Buildly Rabbit:
```
    /\_/\   
   ( o.o )  Buildly Developer Helper
    > ^ <   
    Buildly.io - Build Smarter, Not Harder

Welcome to the Buildly CLI Tool!
Please select an option:
1) Set up Minikube
2) Set up Helm  
3) Set up Buildly Core
4) Set up Buildly Template
5) Set up Services
6) List Buildly Marketplace Services
7) Clone a Buildly Marketplace Service
8) Set up BabbleBeaver AI Framework
9) Exit
```

### Set Up Your Infrastructure

Let's set up the complete environment step by step:

#### 1. Set up Minikube (Kubernetes)

Choose option **1** from the menu.

The CLI will:
- Check if kubectl is installed (install if missing)
- Check if Minikube is installed (install if missing) 
- Verify Docker is available
- Start a local Kubernetes cluster

**What's happening behind the scenes:**
```bash
# Installing kubectl (if needed)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"

# Installing Minikube (if needed)  
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64

# Starting your cluster
minikube start
```

**Expected Output:**
```
✅ kubectl has been installed.
✅ Minikube has been installed.
✅ Docker is available.
🚀 Starting Minikube cluster...
✅ Minikube cluster is running.
```

#### 2. Set up Helm

Choose option **2** from the menu.

This installs Helm (Kubernetes package manager):
```
✅ Helm v3 is already installed and configured.
```

#### 3. Set up Buildly Core

Choose option **3** from the menu.

You'll be prompted:
```
Buildly Core configuration tool. Would you like to use Buildly Core inside Minikube for testing [M/m] or run it separately in a Docker container [D/d]?
```

**For this tutorial, choose `M` (Minikube):**

The CLI will:
- Create a `buildly-core` namespace in Kubernetes
- Deploy the Buildly Core services
- Set up API gateway and service discovery

**Expected Output:**
```
✅ Buildly Core namespace created.
✅ Buildly Core deployed to Minikube.
✅ API Gateway is accessible at: http://192.168.49.2:30080
```

## Step 3: Create Your First Microservice

Now let's create a customer management service with AI assistance!

### Launch the Service Generator

In a new terminal window (keep the first one open), navigate back to the CLI directory:

```bash
cd ~/Projects/buildly-cli
./django.sh
```

You'll see:
```
    /\_/\   
   ( o.o )  Buster the Buildly Rabbit's Django Module Assistant
    > ^ <   
    Buildly.io - Build Smarter, Not Harder

Welcome to the Buildly Django Module Assistant (v1.1.0)
1. Set up a Django Buildly Module
2. Exit
```

Choose option **1**.

### Configure Your Service

The generator will ask several questions:

**Service Name:**
```
Enter the module name: customer-management
```

**Service Description:**
```
Briefly describe the module you are building: 
A customer management system that handles customer profiles, contact information, order history, and preferences for an e-commerce platform
```

**AI Model Generation:**
```
Would you like AI to generate the model names from your description? (Y/n): Y
```

**AI Analysis:**
The AI will analyze your description and suggest models:
```
🤖 Analyzing your description with AI...

Generated model names based on your description:
- Customer: Main customer information and profile data
- ContactInfo: Phone numbers, addresses, and communication preferences  
- OrderHistory: Past orders and purchase behavior
- Preference: Customer preferences for products, communication, etc.
- Profile: Extended customer profile information

Do these models look good? (Y/n): Y
```

**Project Location:**
```
Where would you like to save this project?
Press Enter to use the default: /Users/yourusername/Projects
```

Press Enter to accept the default.

### Watch the Magic Happen! ✨

The AI will now generate your complete microservice:

```
🤖 Generating Django models with AI...
✅ Customer model created with fields: first_name, last_name, email, phone, created_at, updated_at, is_active
✅ ContactInfo model created with relationship to Customer
✅ OrderHistory model created with customer relationship and order tracking
✅ Preference model created with customer preferences
✅ Profile model created with extended customer data

🔧 Generating REST API serializers...
✅ CustomerSerializer with validation and custom fields
✅ ContactInfoSerializer with nested relationships  
✅ OrderHistorySerializer with computed fields
✅ PreferenceSerializer with choice fields
✅ ProfileSerializer with image handling

🚀 Generating ViewSets and API endpoints...
✅ CustomerViewSet with CRUD operations and custom actions
✅ ContactInfoViewSet with filtering and search
✅ OrderHistoryViewSet with date range filtering
✅ PreferenceViewSet with category filtering  
✅ ProfileViewSet with image upload support

🐳 Generating Docker configuration...
✅ Dockerfile optimized for Django production
✅ docker-compose.yml with PostgreSQL database
✅ Environment configuration files

📚 Generating API documentation...
✅ OpenAPI/Swagger documentation
✅ README with setup instructions
✅ Postman collection for testing

🎯 Service 'customer-management' created successfully!
```

### Choose What to Do Next

```
What would you like to do next?
1. Run the Django server
2. View the code in Visual Studio Code  
3. Build another service
4. Exit
```

**Choose option 1** to run your service immediately.

The CLI will:
```bash
🚀 Starting customer-management service...
docker-compose up -d

✅ Service is running at: http://localhost:8000
✅ API Documentation: http://localhost:8000/api/docs/
✅ Admin Interface: http://localhost:8000/admin/
```

## Step 4: Explore Your API

Your service is now running! Let's explore what was created.

### Check the API Documentation

Open your browser and visit:
**http://localhost:8000/api/docs/**

You'll see a beautiful Swagger interface with all your endpoints:

```
Customer Management API v1.0

Endpoints:
GET    /api/customers/           - List all customers
POST   /api/customers/           - Create new customer  
GET    /api/customers/{id}/      - Get customer details
PUT    /api/customers/{id}/      - Update customer
DELETE /api/customers/{id}/      - Delete customer

GET    /api/contact-info/        - List contact information
POST   /api/contact-info/        - Add contact info

GET    /api/order-history/       - List order history  
GET    /api/preferences/         - List customer preferences
GET    /api/profiles/            - List customer profiles
```

### Test the API

Let's create your first customer using curl:

```bash
# Create a customer
curl -X POST http://localhost:8000/api/customers/ \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com", 
    "phone": "+1-555-123-4567"
  }'
```

**Response:**
```json
{
  "id": 1,
  "first_name": "John", 
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone": "+1-555-123-4567",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z", 
  "is_active": true
}
```

### List All Customers

```bash
curl http://localhost:8000/api/customers/
```

### Search Customers

```bash
curl "http://localhost:8000/api/customers/?search=john"
```

### Filter Customers  

```bash
curl "http://localhost:8000/api/customers/?is_active=true"
```

## Step 5: Set Up the Frontend

Let's add a React frontend to interact with your API.

Go back to your first terminal with the Buildly menu and choose option **4: Set up Buildly Template**

```
Would you like to use Buildly React Template? Yes [Y/y] or No [N/n]: Y
```

Choose **Y**.

```
Would you like to deploy the Buildly React Template to Minikube [M/m] or use Docker [D/d]?: D  
```

Choose **D** for Docker (easier for development).

The CLI will:
```bash
✅ Cloning Buildly React Template...
✅ Building React application...  
✅ Starting frontend in Docker container...
✅ Frontend available at: http://localhost:3000
```

### View Your Frontend

Open your browser to **http://localhost:3000**

You'll see a modern React application with:
- Login/authentication interface
- Dashboard with service integration
- API connection to your customer service
- Responsive design components

## Step 6: Add AI Capabilities (Optional)

Let's enhance your application with AI features using BabbleBeaver.

### Set Up BabbleBeaver

From the Buildly menu, choose option **8: Set up BabbleBeaver AI Framework**

```
Would you like to set up BabbleBeaver, our AI and LLM framework? Yes [Y/y] or No [N/n]: Y
```

```  
Would you like to configure BabbleBeaver with OpenAI [O/o] or Gemini [G/g]?: O
```

Choose **O** for OpenAI.

```
✅ BabbleBeaver repository cloned
✅ OpenAI configuration template created
📝 Please add your OpenAI API key to BabbleBeaver/config/openai.yaml
```

### Configure Your API Key

```bash
# Edit the configuration file
nano BabbleBeaver/config/openai.yaml

# Add your OpenAI API key:
openai:
  api_key: "your-openai-api-key-here" 
  model: "gpt-4"
  max_tokens: 2000
  temperature: 0.7
```

### Add AI to Your Service

The CLI will prompt you when working with services:
```
Would you like to integrate BabbleBeaver AI logic into the customer-management service? Yes [Y/y] or No [N/n]: Y
```

This adds AI capabilities like:
- Smart customer insights generation
- Automated email content creation  
- Sentiment analysis of customer feedback
- Intelligent search and recommendations

## Step 7: Verify Everything is Working

Let's make sure all your services are running correctly:

### Check Kubernetes Services

```bash  
kubectl get pods --all-namespaces
```

**Expected Output:**
```
NAMESPACE     NAME                           READY   STATUS    RESTARTS
buildly-core  buildly-core-xxx               1/1     Running   0
default       customer-mgmt-xxx              1/1     Running   0  
kube-system   minikube-xxx                   1/1     Running   0
```

### Check Docker Services

```bash
docker ps
```

**Expected Output:**
```
CONTAINER ID   IMAGE                    STATUS        PORTS
abc123         customer-management      Up 5 minutes  0.0.0.0:8000->8000/tcp
def456         buildly-react-template   Up 3 minutes  0.0.0.0:3000->3000/tcp
ghi789         postgres:13              Up 5 minutes  5432/tcp
```

### Test the Complete Stack

1. **Backend API**: http://localhost:8000/api/docs/
2. **Frontend App**: http://localhost:3000  
3. **Database**: PostgreSQL running in container
4. **Kubernetes Dashboard**: `minikube dashboard`

## Step 8: What's Next?

Congratulations! 🎉 You now have a complete modern application stack running. Here are some next steps:

### Immediate Next Steps

1. **Explore the Generated Code**
   ```bash
   code ~/Projects/customer-management  # Open in VS Code
   ```

2. **Create More Services**
   ```bash
   ./django.sh
   # Try: "order-management", "inventory-system", "notification-service"  
   ```

3. **Customize Your Frontend**
   ```bash
   code ~/Projects/buildly-react-template
   ```

### Learn More

- **[Service Development Tutorial](./service-development.md)** - Deep dive into creating microservices
- **[AI Integration Guide](./ai-integration.md)** - Add intelligent features with BabbleBeaver
- **[Deployment Guide](./deployment.md)** - Deploy to production on AWS, GCP, or Azure
- **[Architecture Overview](./readme.md)** - Understand the complete Buildly ecosystem

### Join the Community

- **Discord**: Join our developer community
- **GitHub**: Contribute to Buildly projects
- **Documentation**: buildly.io/docs
- **Examples**: github.com/buildlyio/examples

## Troubleshooting

### Common Issues

**Minikube won't start:**
```bash
minikube delete
minikube start --driver=docker
```

**Service won't build:**  
```bash
cd customer-management
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**Port conflicts:**
```bash
# Check what's using ports
lsof -i :8000
lsof -i :3000

# Kill processes if needed  
kill -9 <PID>
```

**Permission errors:**
```bash
chmod +x *.sh
sudo chown -R $USER:$USER ~/Projects/buildly-cli
```

### Get Help

- **Documentation Issues**: Check our troubleshooting guide
- **Code Issues**: Review the generated README files  
- **Environment Issues**: Verify Docker and Kubernetes are running
- **Community Support**: Join our Discord server

## Summary

You've successfully:
- ✅ Installed and configured the Buildly CLI
- ✅ Set up a local Kubernetes cluster with Minikube  
- ✅ Deployed Buildly Core API gateway
- ✅ Created an AI-generated microservice with full CRUD API
- ✅ Launched a React frontend application
- ✅ Optionally integrated AI capabilities with BabbleBeaver
- ✅ Verified everything works together

**Your application stack:**
- **Backend**: Django REST API with PostgreSQL
- **Frontend**: React SPA with modern UI components
- **Infrastructure**: Kubernetes with Docker containers
- **AI**: BabbleBeaver framework (if configured)
- **Gateway**: Buildly Core for service discovery and routing

You're now ready to build amazing applications with Buildly! 🚀

---

**Need help?** Check our [troubleshooting guide](./troubleshooting.md) or join our community Discord.