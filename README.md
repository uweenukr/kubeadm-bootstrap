## Kubeadm Bootstrapper

This repository contains a bunch of helper scripts to set up Kubernetes clusters
using `kubeadm`. It is meant for use on bare-metal clusters, as well as VMs
that are being treated like bare-metal clusters for various reasons. 

This is just a wrapper around `kubeadm` to provide sane defaults.

## Pre-requisites

### Empty nodes

Kubernetes takes full control of all the nodes it runs on, so do not do this
on nodes that are also being used for other things.

### Swap turned off

Kubernetes does not support running on Nodes with Swap turned on. Make sure
that swap is turned off on the nodes you are planning on using this on.

### Operating System

This has been tested on Ubuntu 16.04 only. We would welcome patches to support
CentOS / RHEL 7. The Overlay filesystem must be enabled in your kernel - it is
by default, so if you didn't fiddle with it you are good!

### Networking

All nodes in the cluster must have unrestricted outbound internet access. This
is for pulling in Docker images & Debian packages.

At least one node in the cluster must have a public IP if you want to expose
network services to the world (via Ingress).

Ideally traffic between the various nodes is unrestricted by any firewall rules.
If you need list of specific ports to open, please open an issue and we'll
figure it out.

### ssh

You must have ssh access to all the nodes. You also need root :)

## Setting up a cluster

### Setting up a Master Node
  
1. Install the pre-requisites for starting the master:

   ```bash
   git clone https://github.com/uweenukr/kubeadm-bootstrap
   cd kubeadm-bootstrap
   sudo ./install-kubeadm.bash
   ```
   
   This installs `kubeadm`, a supported version of Docker and sets up the
   appropriate storage driver options for Docker.
   
   
2. Setup the master.

   ```bash
   sudo -E ./init-master.bash
   ```
   
   The `-E` after `sudo` is important.

   This will take a minute or two, but should set up and install the following:
   
   a. A Kubernetes Master with all the required components (etcd, apiserver,
      scheduler and controller-manager)

   b. Flannel with VXLAN backend for the Pod Network

   c. Helm for installing software on to the cluster.

   d. An Nginx ingress that is installed on all nodes - this is used to get
      network traffic into the cluster. This is installed via Helm.

   e. Credentials to access the Kubernetes cluster in the currently running user's
      `~/.kube/config` directory.

   The master node is also marked as schedulable - this might not be ideal if
   you are running a large cluster, but is useful otherwise. This also means
   that if you only wanted a single node Kubernetes cluster, you are already
   done!
   
3. Test that everything is up!

   a. Run `kubectl get node` - you should see one node (your master node) marked
      as `Ready`.

   b. Run `kubectl --namespace=kube-system get pod`. Everything should be in
      `Running` state.  If it's still `Pending`, give it a couple minutes. If
       they are in `Error` or `CrashLoopBackoff` state, something is wrong. 

   c. Do `curl localhost`.  It should output `404 Not Found`. This means network

      traffic into the cluster is working. If your master node also has an external
      IP that is accessible from the internet, try hitting that too - it should
      also return the same thing. If not, you might be having firewall issues -
      check to make sure traffic can reach the master node from outside!
   

Congratulations, now you have a single node Kubernetes cluster that can also act
as a Kubernetes master for other nodes!

### Setting up a worker node

1. In your master node, run:

       sudo kubeadm token create --print-join-command
   
   This will print a command that like:

       kubeadm join --token <some-secret> <master-ip>:6443 --discovery-token-ca-cert-hash sha256:<another-secret>
   
   Running this command as `sudo` creates a `token` that can be used by another node to join the
   cluster. This `token` is valid for 24h by default. Treat it very
   securely, since leaking it can compromise your cluster.

2. On the worker node you want to join to the cluster, install the
   pre-requisites:
   ```bash
   git clone https://github.com/uweenukr/kubeadm-bootstrap
   cd kubeadm-bootstrap
   sudo ./install-kubeadm.bash
   ```
   
   This installs `kubeadm`, a supported version of docker and sets up the
   appropriate storage driver options for docker.

3. Copy the `kubeadm join` command you got as output
   of step (1) from the master, prefix with `sudo` and run it. 
   This should take a few minutes.
   
4. Test that everything is up!

   a. On the master, run `kubectl get node`.  It should list your new node in
      `Ready` state.

   b. On the master, run `sudo kubectl --namespace=kube-system get pod -o wide`. This should show
      you a `kube-proxy`, a `kube-flannel` and `kube-controller` pod running on your
      new node in `Ready` state. If it is in `Pending` state, give it a few minutes
      to get to `Ready`. If it's in `Error` or `CrashLoopBackoff` you have a
      problem.

   c. On the new worker node, do `curl localhost`. It should output
      `404 Not Found`. This means network traffic into your cluster
      is working. If this worker node also has a public
      IP that is accessible from the internet, hit that too - you
      should get the same output. If not, you might be having firewall
      issues - check to make sure traffic can reach this worker node
      from outside!
      
Congratulations, you have a working multi-node Kubernetes cluster! You can
repeat these steps to add as many new nodes as you want :)

## Docker Storage Base Directory
By default, Docker puts all of the images and other work files in a directory
on the boot volume of the instance, called `/var/lib/docker`. This is quite
convenient for a simple trial system, but this directory can easily fill up
causing disastrous results for your cluster.

It is highly recommended that you mount an external volume as `/var/lib/docker`
on each host before running the bootstrap script. Don't forget to configure this
mount to be restored upon reboot or else docker will quietly create a new
directory and start storing the files on your boot volume as a ticking time
bomb.
   
## Next step?

1. If you want to install JupyterHub on this cluster, follow the instructions in
   the [Zero to JupyterHub guide](https://z2jh.jupyter.org)
2. You can look for other software to install from the official kubernetes
   charts repository.
