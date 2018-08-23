# ELK Filebeat Chart

> Chart to manage a Filebeat Daemonset deployment that forwards logs to Logstash

## Contents

*   [Overview](#overview)
*   [Prerequisites](#prerequisites)
*   [Getting Started](#quickstart)
*   [Propectors](#prospectors)
*   [Debugging](#debugging)
*   [SSL](#ssl)


---


## Overview

This repository contains the Helm Chart and tools to deploy a Filebeat DaemonSet
with a specified set of prospector configs to a Kubernetes cluster.

Use this Chart whenever you want to add prospectors to the filebeat pods and/or if
the ELK instance the filebeat pods are forwarding logs to was deployed with new
SSL certificates.


---


## Prerequisites

1. Install and configure `kubectl`
2. Install Helm locally and in the namespace that you will be deploying to (Tiller).
3. (Optional) Gather the SSL Cert files that will need to be mounted to the
DaemonSet as a secret for Filebeat to be able to securely forward logs to Logstash
(see [SSL](#ssl) for an example using Certs stored in Credstash)


---


## Getting Started

If you require Filebeat to use SSL connection to Logstash, read [SSL section](#ssl).

By default this deployment includes a number of common Prospectors that will be
needed in almost every environment. However you will want to add more prospectors
for deployment/application specific log collection. See [Propectors](#prospectors)
section for info.

Add the values for your environment to the `environments/` folder. Then apply.
Below is an example of deploying Filebeat for the `prod-elk` VPC/cluster:
```
helm2.9.0 install . --name=filebeat --kube-context=prod-elk --namespace=monitor --tiller-namespace=monitor --values=environments/prod-elk.yaml
```


---


## Prospectors

> NOTE: In Elastic Beats version 6.0 and higher the format of prospector files
and some of the fields in those files are changed slightly
([6.0 Breaking Changes](https://www.elastic.co/guide/en/beats/libbeat/current/breaking-changes-6.0.html)).
These charts account for those changes but if you're using a filebeat image >= 6.0
then make sure to set `filebeatVersionGte6: true` value to true.

This Chart allows you deploy the filebeat DaemonSet with prospector configs that
you define in any of the three ways listed below. _The `templates/configmap-prospectors.yaml`
template will be populated with the common prospectors first, the custom prospectors next,
and finally the templated prospectors, so account for any overlap._
> **BEWARE of GOTCHA:** Always use the `.yml` (_NOT_ .yaml) extension when defining prospectors!
You'll run into unexpected behavior including the filebeats not using the prospectors
if you include the `a`!

1. **Common Prospectors**<br/><br/>
There are a number of default common Prospectors that almost every environment
will need. These can be found in [prospectors/common](prospectors/common). These
include prospectors that scrape logs from kube-system, heapster, filebeat, etc.
Use these by setting the `prospectors.common.enabled` value to `true`.

2. **Custom Prospectors**<br/><br/>
Manually add more prospector configs by setting the `prospectors.custom.enabled`
value to `true` and adding some files to the `prospectors/custom` folder that
will be pulled into `templates/configmap-prospectors.yaml`. If you're deploying to
a Kubernetes cluster with multiple namespaces that need their logs aggregated and sent
to a common Logstash instance, this will require copy pasting the prospector files
per namspace and changing a few values repetitively. Sometimes this may be necessary,
but depending on your needs, using the _Templated Prospectors_ may be better.

3. **Templated Prospectors**<br/><br/>
Provide a values file to the helm (install | upgrade) command that includes
the some prospector config values for common log type that need to be collected.
Let's take a snippet of the [environments/local.yaml](environments/local.yaml) values file for example:
    ```yml
    prospectors:
      common:
        enabled: true
      custom:
        enabled: false
      templates:
        enabled: true
        winston:
          ############################################################################
          # WINSTON VOTING PROSPECTORS
          ############################################################################
          - namespaces:
              - test1
              - test2
            formats:
              - winston
            services:
              - winston-service1
              - winston-service2
              - winston-service3
    ```
    As you can see in the Chart's default [values.yaml](values.yaml) file we have a list of some
    known prospector types/configs, such as `winston`. In
    [templates/configmap-prospectors.yaml](templates/configmap-prospectors.yaml)
    we have some templating logic to include a winston prospector file in the config map
    per namespace that-that prospector will be searching for logs from. In that namespace
    it will be looking for log paths that contain values defined in `services` from
    the exampe above. In other words, these values, combined with the templating logic,
    will create a prospector for each of the defined namespaces, where each prospector
    collects logs from those service pods in that namespace (there will be a prospector
    collecting logs from the winston-service1, winston-service2, etc. in the test1 namespace,
    there will be a prospector
    collecting logs from the winston-service1, winston-service2, etc. in the test1 namespace,
    etc. etc. etc.). This succinct yaml syntax for these values makes it easy to
    deploy a Filebeat Daemonset that collects logs from multiple application
    clusters separated by namespace in one Kubernetes Cluster.

    [values.yaml](values.yaml) shows the syntax used for defining the prospectors using the
    [prospectors/prospector-value-type.yaml](templates/configmap-prospectors.yaml).
    Using this method of templating is much cleaner than copy-pasting prospector
    files for each namspace and changing the same few values over and over again.
    [values.yaml](values.yaml) reflects the currently supported
    well known prospector types that are templated out in
    [templates/configmap-prospectors.yaml](templates/configmap-prospectors.yaml).
    To add more, add more prospector templating logic to
    [templates/configmap-prospectors.yaml](templates/configmap-prospectors.yaml)
    similar to the way the current ones have been defined.


---


## Debugging

A useful way to test that the templates/configmap-prospectors.yaml creates the
prospector config files you expect it to, given common, custom, and templated
prospectors is to use the `helm template` functionality:

```
# With some prospector values of common local namespaces and services
helm template . --values=environments/local.yaml -x templates/configmap-prospectors.yaml
--OR--
# With some prospector values of your Kubernetes/App cluster specific namespaces and services
helm template . --values=your-prospector-values.yaml -x templates/configmap-prospectors.yaml
```
