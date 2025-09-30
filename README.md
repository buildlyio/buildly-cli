# Buildly CLI 🚀

**Build AI-powered microservices in minutes, not months.**

The Buildly CLI is a comprehensive toolkit for creating modern, scalable applications with microservices architecture, AI integration, and cloud-native deployment. Generate complete Django APIs with AI, deploy to Kubernetes, and integrate intelligent features - all from the command line.

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![GitHub Stars](https://img.shields.io/github/stars/buildlyio/buildly-cli)](https://github.com/buildlyio/buildly-cli/stargazers)
[![Discord](https://img.shields.io/badge/Discord-Join%20Community-7289da)](https://discord.com/channels/908423956908896386/908424004916895804)

![Buildly CLI Demo](images/cli-help.png)

## ✨ Features

- 🤖 **AI-Powered Code Generation** - Describe your app, get production-ready Django APIs
- ☸️ **Kubernetes Native** - Built-in support for Minikube and cloud deployment
- 🔧 **Microservices Architecture** - Scalable services with Buildly Core gateway
- 🧠 **BabbleBeaver AI Framework** - Integrate OpenAI, Gemini, and other LLMs
- 🛒 **Marketplace Integration** - Pre-built services for common use cases
- 📱 **Frontend Templates** - React applications with API integration
- 🐳 **Docker Everything** - Containerized development and deployment

## 🚀 Quick Start

**Create your first AI-powered application in 5 minutes:**

```bash
# 1. Clone and setup
git clone https://github.com/buildlyio/buildly-cli.git
cd buildly-cli
chmod +x *.sh

# 2. Launch the development environment
source dev.sh
# Choose: 1 (Minikube) → 2 (Helm) → 3 (Buildly Core)

# 3. Generate your first microservice  
./django.sh
# Describe: "Customer management system with order tracking"
# Watch AI generate complete Django API with models, views, serializers

# 4. Your API is live at http://localhost:8000/api/docs/
```

**That's it!** You now have a complete microservice with:
- RESTful API endpoints with auto-generated documentation
- Database integration with PostgreSQL
- Docker containerization and Kubernetes deployment
- AI-powered features ready for integration

## 📚 Documentation

| Guide | Description | Time |
|-------|-------------|------|
| **[🚀 Getting Started](docs/getting-started.md)** | Complete tutorial from zero to deployed app | 30 min |
| **[🔧 Quick Reference](docs/quick-reference.md)** | Commands, troubleshooting, and tips | 5 min |
| **[🏗️ Architecture Guide](docs/readme.md)** | Complete system overview and components | 15 min |
| **[⚙️ Environment Setup](docs/environment-setup.md)** | Detailed setup instructions | 20 min |
| **[🤖 AI Integration](docs/ai-integration.md)** | BabbleBeaver AI framework guide | 25 min |
| **[🚢 Deployment](docs/deployment.md)** | Production deployment to AWS, GCP, Azure | 45 min |

## 🎯 What You Can Build

### 🏢 Enterprise Applications
- **Customer Management** - CRM with AI insights and automation
- **Inventory Systems** - Smart stock management with predictive analytics  
- **HR Platforms** - Employee management with intelligent workflows

### 🛒 E-commerce Platforms
- **Product Catalogs** - AI-powered search and recommendations
- **Order Management** - Complete order lifecycle with notifications
- **Payment Processing** - Secure transactions with fraud detection

### 📊 Data & Analytics
- **Business Intelligence** - Real-time dashboards with AI insights
- **Customer Analytics** - Behavior analysis and predictive modeling
- **Reporting Systems** - Automated report generation and distribution

## 🛠️ Prerequisites

**Required:**
- macOS or Linux (Windows via WSL2)
- Bash shell
- Git 2.17+
- 8GB+ RAM
- 10GB+ free disk space

**Auto-installed by CLI:**
- Docker 19+
- Kubernetes (Minikube)
- Helm 3+
- kubectl

**Optional (for AI features):**
- OpenAI API key
- Google Gemini API key

## 📦 Installation

### Standard Installation

```bash
# Clone the repository
git clone https://github.com/buildlyio/buildly-cli.git
cd buildly-cli

# Make scripts executable  
chmod +x *.sh

# Initialize submodules (if any)
git submodule update --init --recursive

# Start building!
source dev.sh
```

### Development Installation

```bash
# Fork the repository first, then:
git clone https://github.com/YOUR_USERNAME/buildly-cli.git
cd buildly-cli

# Set up development environment
chmod +x *.sh
source dev.sh

# Pull latest changes (with submodules)
git pull --recurse-submodules
```

## 🎮 Usage Examples

### Create a Customer Service
```bash
./django.sh
# Service: customer-service
# Description: "Customer profiles with contact info and preferences"
# Result: Complete CRUD API with AI-generated models
```

### Add AI Capabilities  
```bash
source dev.sh
# Option 8: Set up BabbleBeaver AI Framework
# Choose OpenAI or Gemini
# Integration: Smart search, content generation, analytics
```

### Deploy to Production
```bash
# Kubernetes deployment (automated)
kubectl apply -f customer-service/k8s/

# Or use Helm for complex deployments
helm install my-app ./helm-chart
```

## 🏗️ Architecture

The Buildly CLI creates a complete microservices ecosystem:

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

**Core Components:**
- **Buildly Core** - API gateway, authentication, service discovery
- **Microservices** - AI-generated Django applications with PostgreSQL
- **BabbleBeaver** - AI/LLM integration framework  
- **Frontend** - React templates with API integration
- **Infrastructure** - Kubernetes/Docker deployment automation

## 🌟 Community & Support

Join our vibrant community to get help, share ideas, and collaborate with other developers:

### 💬 Get Help & Connect
- 🎮 **[Discord Server](https://discord.com/channels/908423956908896386/908424004916895804)** - Real-time discussions, support, and community engagement
- 🤝 **[Buildly Collaboration Platform](https://collab.buildly.io)** - Find technical co-founders, resources, and contribute to open source projects
- 📖 **[Documentation](docs/)** - Comprehensive guides and tutorials
- 🐛 **[GitHub Issues](https://github.com/buildlyio/buildly-cli/issues)** - Bug reports and feature requests

### 🚀 What Our Community Offers
- **Technical Support** - Get help with setup, development, and deployment
- **Open Source Contributions** - Contribute to Buildly projects and ecosystem
- **Co-founder Matching** - Connect with potential technical co-founders
- **Resource Sharing** - Access templates, examples, and best practices
- **Learning Opportunities** - Workshops, tutorials, and knowledge sharing

Whether you're a beginner looking to learn or an expert wanting to contribute, our community welcomes developers of all skill levels!

## 🤝 Contributing

We love contributions from the community! Here's how you can help make Buildly CLI even better:

### Ways to Contribute
- 🐛 **Report Bugs** - Found an issue? [Open a bug report](https://github.com/buildlyio/buildly-cli/issues/new)
- 💡 **Request Features** - Have an idea? [Submit a feature request](https://github.com/buildlyio/buildly-cli/issues/new)
- 📝 **Improve Documentation** - Help us make our docs clearer and more comprehensive
- 🔧 **Submit Code** - Fix bugs, add features, or improve performance
- 🛒 **Share Services** - Contribute to the Buildly Marketplace with reusable services
- 🤖 **Enhance AI** - Improve BabbleBeaver AI capabilities and integrations

### Development Setup
```bash
# Fork and clone your fork
git clone https://github.com/YOUR_USERNAME/buildly-cli.git
cd buildly-cli

# Set up development environment
chmod +x *.sh
source dev.sh

# Create feature branch
git checkout -b feature/your-feature-name

# Make your changes and test
./django.sh  # Test service generation
source dev.sh  # Test environment setup

# Commit and push
git commit -am "Add your feature"
git push origin feature/your-feature-name

# Create Pull Request
```

### Code of Conduct
Please read our [Contributing Guidelines](https://github.com/buildlyio/docs/blob/master/CONTRIBUTING.md) for details on our code of conduct and development process.

## 📋 Versioning & Releases

We use [Semantic Versioning](http://semver.org/) for version management:

- **Major** (1.0.0) - Breaking changes
- **Minor** (1.1.0) - New features, backward compatible
- **Patch** (1.1.1) - Bug fixes, backward compatible

**Current Version**: See [latest release](https://github.com/buildlyio/buildly-cli/releases/latest)  
**All Versions**: View [all releases](https://github.com/buildlyio/buildly-cli/releases)

### Release Notes
Each release includes:
- ✨ New features and improvements
- 🐛 Bug fixes and patches  
- 📖 Documentation updates
- ⚠️ Breaking changes (if any)
- 🔄 Migration guides

## 👥 Authors & Contributors

### Core Team
- **Buildly Team** - *Initial development and architecture*
- **Community Contributors** - *Features, bug fixes, and improvements*

### Recognition
Special thanks to all our [contributors](https://github.com/buildlyio/buildly-cli/graphs/contributors) who have helped make Buildly CLI better:

- 🏆 **Top Contributors** - Regular code contributors
- 📝 **Documentation Heroes** - Documentation improvers  
- 🐛 **Bug Hunters** - Issue reporters and debuggers
- 🎨 **UI/UX Enhancers** - Interface and experience improvers
- 🤖 **AI Pioneers** - BabbleBeaver framework contributors

*Want to see your name here? [Start contributing today!](https://github.com/buildlyio/buildly-cli/issues)*

## ⚖️ License

This project is licensed under the **GPL v3 License** - see the [LICENSE](LICENSE) file for complete details.

### What This Means
- ✅ **Free to use** - Use Buildly CLI for any purpose
- ✅ **Modify freely** - Adapt the code to your needs
- ✅ **Distribute** - Share with others under the same license
- ✅ **Commercial use** - Use in commercial projects
- ⚠️ **Copyleft** - Derivative works must use the same GPL v3 license
- ⚠️ **No warranty** - Provided "as-is" without warranties

### Commercial Support
Need commercial support, custom development, or enterprise features?  
Contact us at: **enterprise@buildly.io**

---

## 🚀 Ready to Build?

**[👉 Get Started Now](docs/getting-started.md)** - Create your first AI-powered microservice in 30 minutes!

### Quick Links
- 📚 [Complete Documentation](docs/)
- 🎮 [Join Discord Community](https://discord.com/channels/908423956908896386/908424004916895804)
- 🤝 [Buildly Collaboration Platform](https://collab.buildly.io)
- 🐛 [Report Issues](https://github.com/buildlyio/buildly-cli/issues)
- ⭐ [Star on GitHub](https://github.com/buildlyio/buildly-cli)

**Build smarter, not harder.** 🚀
