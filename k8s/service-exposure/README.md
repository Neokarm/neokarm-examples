# Service Exposure

This guide will explain how to expose kubernetes services externally, to be consumed outside of the kubernetes cluster, with high availability.

- [Load Balancer Controller Integration](#load-balancer-controller-integration)
- [Manual Setup](#manual-setup)

## [Load Balancer Controller](<(https://github.com/kubernetes-sigs/aws-load-balancer-controller)>) Integration

### zCompute v22.02+

> **Work In Progress**

zCompute's AWS API can be leveraged to be used with AWS Load Balancer Controller to provision NLBs and ALBs that will operate as a Kubernetes `Ingress` or as an external LoadBalancer `Service`.

### zCompute <v22.02

Use the [Manual Setup](#manual-setup) as a workaround.

## Manual Setup

Two optional approches:

- **Load Balancing `NodePort` Services:**

  In this method you create `NodePort` services for deploymnets you wish to expose, and use a load balancer to route traffix to this port for all kubernetes worker nodes.

  Create a target group with all kubernetes worker nodes as targets, with the target port being, the port specified by the `NodePort` service specification. Forward traffic to this target group, in one of the following ways:

  - Dedicate a Load Balancer to a single service - 1-to-1 loadbalancer-service relation.
  - Dedicate a Listener to a single service - the load balancer will traffic to multiple services according to the listener port.
  - Rule-based traffic routing - a single load balancer and listener is used, traffic is routed according to load balancer rules such as HTTP path, hostname, headers, etc...

  This method requires a lot of manual integration but offers the most flexibility in terms of traffic routing logic.

- **Web Server Ingress:**

  In this method you expose services using a web-server-based ingress such as [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/) (which also comes pre-installed on the RKE2 cluster installed by the provided terraform) or [HAProxy Ingress](https://haproxy-ingress.github.io/). Exposing the services is done in a kubernetes-native way, according to the the specific ingress provider.

  To provide load balancing and high availablity to this ingress, you need to create a load balancer to the ingress service, as described in the previous bullet.

  This method can be viewed as a one-time setup method, where you just configure loadbalancing the ingress service `NodePort`, and then exposing other services in a kubernetes-native way using the ingress controller. The downsides of this method is that the traffic routing is limited by the ingress controller capabilities.
