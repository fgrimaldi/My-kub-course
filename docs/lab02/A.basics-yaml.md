# Yaml Basics

YAML, which stands for Yet Another Markup Language, or YAML Ain’t Markup Language (depending who you ask) is a human-readable text-based format for specifying configuration-type information.

Using YAML for K8s definitions gives you a number of advantages, including:

-   Convenience: You’ll no longer have to add all of your parameters to the command line
-   Maintenance: YAML files can be added to source control, so you can track changes
-   Flexibility: You’ll be able to create much more complex structures using YAML than you can on the command line

YAML is a superset of JSON, which means that any valid JSON file is also a valid YAML file. So on the one hand, if you know JSON and you’re only ever going to write your own YAML (as opposed to reading other people’s) you’re all set.

There are two types of structure in YAML:

-   Lists
-   Maps

That’s it. You might have maps of lists and lists of maps, and so on, but if you’ve got those two structures down, you’re all set. That’s not to say there aren’t [more complex things you can do](http://www.yaml.org/refcard.html), but in general, this is all you need to get started.


## YAML Maps

Let’s start by looking at YAML maps. Maps let you associate name-value pairs, which of course is convenient when you’re trying to set up configuration information. For example, you might have a config file that starts like this:
```
---
apiVersion: v1
kind: Pod
```

The first line is a separator, and is optional unless you’re trying to define multiple structures in a single file. From there, as you can see, we have two values, v1 and Pod, mapped to two keys, apiVersion and kind.

This kind of thing is pretty simple, of course, and you can think of it in terms of its JSON equivalent:

```
{
   "apiVersion": "v1",
   "kind": "Pod"
}
```

Notice that in our YAML version, the quotation marks are optional; the processor can tell that you’re looking at a string based on the formatting.

You can also specify more complicated structures by creating a key that maps to another map, rather than a string, as in:

```
---
apiVersion: v1
kind: Pod
metadata:
  name: website
  labels:
    app: application01
```

In this case, we have a key, metadata, that has as its value a map with 2 more keys, name and labels. The labels key itself has a map as its value. You can nest these as far as you want to.

The YAML processor knows how all of these pieces relate to each other because we’ve indented the lines. In this example I’ve used 2 spaces for readability, but the number of spaces doesn’t matter — as long as it’s at least 1, and as long as you’re CONSISTENT. For example, name and labels are at the same indentation level, so the processor knows they’re both part of the same map; it knows that app is a value for labels because it’s indented further.

*Quick note: NEVER use tabs in a YAML file.*

So if we were to translate this to JSON, it would look like this:
```
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
               "name": "website",
               "labels": {
                          "app": "application01"
                         }
              }
}
```
Now let’s look at lists.

## YAML lists

YAML lists are literally a sequence of objects. For example:
```
args:
  - sleep
  - "10000"
  - message
  - "Kubernetes courses sleeping"
```
As you can see here, you can have virtually any number of items in a list, which is defined as items that start with a dash (-) indented from the parent. So in JSON, this would be:
```
{
   "args": ["sleep", "10000", "message", "Kubernetes courses sleeping"]
}
```
And of course, members of the list can also be maps:
```
---
apiVersion: v1
kind: Pod
metadata:
  name: website
  labels:
    app: application01
spec:
  containers:
    - name: nginx
      image: nginx
      ports:
        - containerPort: 80
    - name: mysql
      image: mysql:5.7
      ports:
        - containerPort: 3306
```

So as you can see here, we have a list of containers “objects”, each of which consists of a name, an image, and a list of ports. Each list item under ports is itself a map that lists the containerPort and its value.

For completeness, let’s quickly look at the JSON equivalent:
```
{
   "apiVersion": "v1",
   "kind": "Pod",
   "metadata": {
                 "name": "website",
                 "labels": {
                             "app": "application01"
                           }
               },
    "spec": {
       "containers": [{
                       "name": "nginx",
                       "image": "nginx",
                       "ports": [{
                                  "containerPort": "80"
                                 }]
                      },
                      {
                       "name": "mysql",
                       "image": "mysql:5.7",
                       "ports": [{
                                  "containerPort": "3306"
                                 }]
                      }]
            }
}
```
As you can see, we’re starting to get pretty complex, and we haven’t even gotten into anything particularly complicated! No wonder YAML is replacing JSON so fast.

So let’s review. We have:

-   maps, which are groups of name-value pairs
-   lists, which are individual items
-   maps of maps
-   maps of lists
-   lists of lists
-   lists of maps


Basically, whatever structure you want to put together, you can do it with those two structures.

Creating a Pod using YAML

OK, so now that we’ve got the basics out of the way, let’s look at putting this to use. We’re going to first create a Pod using YAML.

Back already? Great! Let’s start with a Pod.


## What does each apiVersion mean?
Kubernetes have 3 different API version state (alpha, beta, stable).

__alpha__
API versions with ‘alpha’ in their name are early candidates for new functionality coming into Kubernetes. These may contain bugs and are not guaranteed to work in the future.

__beta__
in the API version name means that testing has progressed past alpha level, and that the feature will eventually be included in Kubernetes. Although the way it works might change, and the way objects are defined may change completely, the feature itself is highly likely to make it into Kubernetes in some form.

__stable__
These do not contain ‘alpha’ or ‘beta’ in their name. They are safe to use.

We will use stable where possible.

You can control your API version using this command line:
```
student@master:~$ kubectl api-versions
```

```
admissionregistration.k8s.io/v1beta1
apiextensions.k8s.io/v1beta1
apiregistration.k8s.io/v1
apiregistration.k8s.io/v1beta1
apps/v1
apps/v1beta1
apps/v1beta2
authentication.k8s.io/v1
authentication.k8s.io/v1beta1
authorization.k8s.io/v1
authorization.k8s.io/v1beta1
autoscaling/v1
autoscaling/v2beta1
autoscaling/v2beta2
batch/v1
batch/v1beta1
certificates.k8s.io/v1beta1
coordination.k8s.io/v1
coordination.k8s.io/v1beta1
crd.projectcalico.org/v1
events.k8s.io/v1beta1
extensions/v1beta1
networking.k8s.io/v1
networking.k8s.io/v1beta1
node.k8s.io/v1beta1
policy/v1beta1
rbac.authorization.k8s.io/v1
rbac.authorization.k8s.io/v1beta1
scheduling.k8s.io/v1
scheduling.k8s.io/v1beta1
storage.k8s.io/v1
storage.k8s.io/v1beta1
v1
```

__v1__ will be also called __core__ because contain many objects. core object are not belongs to any api groups.


Here you can find some description of what is called api group:

__v1__
This was the first stable release of the Kubernetes API. It contains many core objects.

__apps/v1__
apps is the most common API group in Kubernetes, with many core objects being drawn from it and v1. It includes functionality related to running applications on Kubernetes, like Deployments, RollingUpdates, and ReplicaSets.

__autoscaling/v1__
This API version allows pods to be autoscaled based on different resource usage metrics. This stable version includes support for only CPU scaling, but future alpha and beta versions will allow you to scale based on memory usage and custom metrics.

__batch/v1__
The batch API group contains objects related to batch processing and job-like tasks (rather than application-like tasks like running a webserver indefinitely). This apiVersion is the first stable release of these API objects.

__batch/v1beta1__
A beta release of new functionality for batch objects in Kubernetes, notably including CronJobs that let you run Jobs at a specific time or periodicity.

__certificates.k8s.io/v1beta1__
This API release adds functionality to validate network certificates for secure communication in your cluster. You can read more on the official docs.

__extensions/v1beta1__
This version of the API includes many new, commonly used features of Kubernetes. Deployments, DaemonSets, ReplicaSets, and Ingresses all received significant changes in this release.

__policy/v1beta1__
This apiVersion adds the ability to set a pod disruption budget and new rules around pod security.

__rbac.authorization.k8s.io/v1__
This apiVersion includes extra functionality for Kubernetes role-based access control. This helps you to secure your cluster. Check out the official blog post.

Consider to control your apiVersion every time you are creating new objects

Which apiVersion I should use for POD?
```
student@master:~$ kubectl api-resources | grep pods
```

```
NAME                              SHORTNAMES   APIGROUP   NAMESPACED   KIND
pods                              po                                          true         Pod
podsecuritypolicies               psp          extensions                     false        PodSecurityPolicy
podsecuritypolicies               psp          policy                         false        PodSecurityPolicy
```

Pod do not belongs to any APIGROUP, because pod are a core object.
So we will use __v1__.

## How you can create your yaml file?
 In Kubernetes website you can find a Reference:
 https://kubernetes.io/docs/reference/

 choice the correct version, and under WORKLOADS APIS you can read __Pod v1 core__

Here you can see all reference of configuration file.

## Creating the pod file

In our previous example, we described a simple Pod using YAML:

```
---
apiVersion: v1
kind: Pod
metadata:
  name: website
  labels:
    app: application01
spec:
  containers:
    - name: nginx
      image: nginx
      ports:
        - containerPort: 80
```

Taking it apart one piece at a time, we start with the API version; here it’s just v1.

```
student@master:~$ kubectl api-versions
```
```
<output_omitted>
v1
```


Next, we’re specifying that we want to create a Pod; we might specify instead a Deployment, Job, Service, and so on, depending on what we’re trying to achieve.
```
student@master:~$ kubectl api-resources  -o wide | grep Pod
```
```
pods                              po                                          true         Pod                              [create delete deletecollection get list patch update watch]
podtemplates                                                                  true         PodTemplate                      [create delete deletecollection get list patch update watch]
horizontalpodautoscalers          hpa          autoscaling                    true         HorizontalPodAutoscaler          [create delete deletecollection get list patch update watch]
podsecuritypolicies               psp          extensions                     false        PodSecurityPolicy                [create delete deletecollection get list patch update watch]
poddisruptionbudgets              pdb          policy                         true         PodDisruptionBudget              [create delete deletecollection get list patch update watch]
podsecuritypolicies               psp          policy                         false        PodSecurityPolicy                [create delete deletecollection get list patch update watch]
```

Next we specify the metadata. Here we’re specifying the name of the Pod, as well as the label we’ll use to identify the pod to Kubernetes.

Finally, we’ll specify the actual objects that make up the pod. The spec property includes any containers, storage volumes, or other pieces that Kubernetes needs to know about, as well as properties such as whether to restart the container if it fails. You can find a [complete list of Kubernetes Pod properties](http://kubernetes.io/docs/api-reference/v1/definitions/#_v1_podspec) in the [Kubernetes API specification](http://kubernetes.io/docs/api/), but let’s take a closer look at a typical container definition:

In this case, we have a simple, fairly minimal definition: a name (nginx), the image on which it’s based (nginx), and one port on which the container will listen internally (80). Of these, only the name is really required, but in general, if you want it to do anything useful, you’ll need more information.

You can also specify more complex properties, such as a command to run when the container starts, arguments it should use, a working directory, or whether to pull a new copy of the image every time it’s instantiated. You can also specify even deeper information, such as the location of the container’s exit log. Here are the [properties you can set for a Container](http://kubernetes.io/docs/api-reference/v1/definitions/#_v1_container):

-   name
-   image
-   command
-   args
-   workingDir
-   ports
-   env
-   resources
-   volumeMounts
-   livenessProbe
-   readinessProbe
-   lifecycle
-   terminationMessagePath
-   imagePullPolicy
-   securityContext
-   stdin
-   stdinOnce
-   tty


## kubectl explain pods,svc                       # get the documentation for pod and svc manifests




Now let’s go ahead and actually create the pod.





[Back](lab02.md)
