# kubinator
Deployment scripts for K8s cluster  
Note: this is for ***development only*** and not production and comes with absolutely no guarantees or
suppport of any kind.

## Install Dependencies
There is no Linux distribution requirements here other than something that support
***VirtualBox*** and ***Ruby***

### Ubuntu Dependencies
I've validated with Ubuntu 16.04 and the following versions
* ruby 2.3.1
* vagrant 1.8.1
* virtualbox 5.0.32

Install deps, run:

```bash
sudo apt-get install virtualbox vagrant ruby
```

### Arch Linux Dependencies
Install deps, run:

```bash
sudo pacman -S virtualbox vagrant ruby
```

### Ruby Gem Dependencies
Install ruby gem dependencies

```bash
sudo gem install colorize --no-user-install
sudo gem install filesize --no-user-install
sudo gem install net-ssh --no-user-install
sudo gem install net-scp --no-user-install
```

NOTE: If you get an error in Ubuntu stating that 'mkmf' not found, this should resolve this issue:
```bash
sudo apt-get install ruby-dev
```

### Install Kubectl and Helm

1. Install ***kubectl***

    ```bash
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
    ```
2. Install ***helm***

    ```bash
    curl -LO https://storage.googleapis.com/kubernetes-helm/helm-v2.3.1-linux-amd64.tar.gz
    tar xvzf helm-v2.3.1-linux-amd64.tar.gz
    chmod +x linux-amd64/helm
    sudo mv linux-amd64/helm /usr/local/bin/
    ```

## Deploy Kubernetes

1. Download latest vagrant box  
    https://hpe.sharepoint.com/teams/NCSLA/Shared%20Documents/images

2. Deploy vagrant nodes
    ```bash
    ./kubinator.rb deploy --nodes=10,11,12 --box=k8snode-1.0.156.box
    ```
    Note: i'd recommend taking a snapshot of your vms at this point

3. Add node IPs to no_proxy  
    ```bash
    export no_proxy=$no_proxy,192.168.56.10,192.168.56.11,192.168.56.12
    ```

4. Deploy K8s on vagrant nodes
    ```bash
    ./kubinator.rb deploy --cluster
    ```
    Note: i'd recommend taking another snapshot of your vms at this point
    Note: if this step seems to hang at the "waiting for the control plane
    to become ready" stage (i.e. more than 10min) ensure that your
    ***no_proxy*** includes your nodes as configured in the previous step.

5. Access k8s cluster  
    The deployment process will configure a ***kubernetes-admin@kubernetes*** context
    ```bash
    kubectl config use-context kubernetes-admin@kubernetes
    # Example: kubectl get po --all-namespaces -o wide
    ```

### Vagrant Node Access
You can access the nodes using *vagrant* for your username and password  
Example shell into a node:
```bash
ssh vagrant@192.168.56.10
```

Example scp out a file:
```bash
scp vagrant@192.168.56.10:/etc/kubernetes/kubelet.conf .
```
