# Buildly CLI

Command line tool for creating and configuring your Buildly Logic Modules and to setup your Dev Encrionment.
Also Buildy Helper AI, to help answer anyquestions and guide you in configuring your services, and deploying them.

![Buildly CLI --help](images/cli-help.png)

## Community & Support

Join our vibrant community to get help, share ideas, and collaborate with other developers:

🎮 **[Discord Server](https://discord.com/channels/908423956908896386/908424004916895804)** - Real-time discussions, support, and community engagement  
🤝 **[Buildly Collaboration Platform](https://collab.buildly.io)** - Find technical co-founders, resources, and contribute to open source projects

Whether you're looking for technical support, want to contribute to open source projects, or seeking to connect with potential co-founders, our community platforms are the perfect place to start!

## Getting Started

After forking and installing all prerequisites, you can run the following command to start creating your first app `init.sh` to setup your AI coding and architecture assistant. The instructions will help you to create and configure a completely new Buildly application with services pulled directly from Buildly Marketplace or build brand new ones.

### Prerequisites

Basic prerequisites are:
* Bash command line
* cURL version 7
* git version 2.17

You might also need one or more of the following apps depending on the functionalities you're going to use:
* ollama
* kubectl
* docker version 19+
* helm version 2+
* minikube version 1.5
* python version 3
* aws-cli version 1.16+
* gcloud version 273.0+
* doctl version 1.36+

### Installing

This repository has links to submodules.  
After cloning the repository initalize the sub modules:
>`git submodule update --init`

To pull the latest changes from the submodules use:
>`git pull --recurse-submodules`

To commit changes use:
>`git commit -am 'added module`

To get started just run the init.sh script

MacOS:
`source init.sh`

Linux:
`bash init.sh`

## Contributing

Please read [CONTRIBUTING.md](https://github.com/buildlyio/docs/blob/master/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/buildlyio/buildly-cli/tags).

## Authors

* **Buildly CLI** - *Initial work*

See also the list of [contributors](https://github.com/buildlyio/buildly-cli/graphs/contributors) who participated in this project.

## License

This project is licensed under the GPL v3 License - see the [LICENSE](LICENSE) file for details.
