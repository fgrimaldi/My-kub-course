# Requiring a PodSecurityPolicy

In addition to RBAC authorization, Kube offers another layer of control of what can and cannot be run in your cluster, in the form of *PodSecurityPolicy* objects (PSPs). PSPs are evaluated after a request to the API has been made and authenticated but before the corresponding action is accepted, and serve as a final opportunity to modify or reject that request. By the end of this exercise, you should be able to:

 - Impose a Kubernetes PodSecurityPolicy to enforce strong security profiles for pods.

1.  By default, UCP grants all users a completely open PodSecurityPolicy, effectively disabling the feature. To enable it, as an admin in UCP navigate **Access Control -> Grants -> Kubernetes**, and delete the role `ucp:all:privileged-psp-role` (be careful to only delete this role! Other PSP roles are used by UCP system components).

2.  Try to create a very simple pod as a non-admin user (either through the UCP frontend or through that user's client bundle). Make sure the user has edit rights to the `default` namespace:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: demo
      namespace: default
    spec:
      containers:
      - name: demo
        image: centos:7
        command: ["sleep", "10000"]
    ```

    The request will fail with the message *unable to validate against any pod security policy*; with the global permissive PSP grant removed, at this point no user will be able to create any pods.

3.  Let's create our own completely permissive PSP to begin with, equivalent to not enforcing a PSP at all (adapted from [https://kubernetes.io/docs/concepts/policy/pod-security-policy/](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)); as a UCP admin, create the following:

    ```yaml
    apiVersion: policy/v1beta1
    kind: PodSecurityPolicy
    metadata:
      name: psp
      annotations:
        seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
    spec:
      privileged: true
      allowPrivilegeEscalation: true
      allowedCapabilities:
      - '*'
      volumes:
      - '*'
      hostNetwork: true
      hostPorts:
      - min: 0
        max: 65535
      hostIPC: true
      hostPID: true
      runAsUser:
        rule: 'RunAsAny'
      seLinux:
        rule: 'RunAsAny'
      supplementalGroups:
        rule: 'RunAsAny'
      fsGroup:
        rule: 'RunAsAny'
    ```

    You should be able to see this in UCP under **Kubernetes -> Configurations** if successful.

4.  We'll also need a role we can bind to service accounts that allows the use of this PSP; create the following ClusterRole:

    ```yaml
    kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: psprole
    rules:
    - apiGroups: ['policy']
      resources: ['podsecuritypolicies']
      verbs:     ['use']
      resourceNames:
      - psp
    ```

5.  Let's create a service account to grant usage of this PSP to:

    ```yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: pspbot
      namespace: default
    ```

6.  Bind the ClusterRole and ServiceAccount together:

    ```yaml
    kind: ClusterRoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: pspbinding
    roleRef:
      kind: ClusterRole
      name: psprole
      apiGroup: rbac.authorization.k8s.io
    subjects:
    - kind: ServiceAccount
      name: pspbot
      namespace: default
    ```

7.  At this point, our `pspbot` service account should be able to create any pod it likes with the wide-open PodSecurityPolicy we've authorized it to use; try it out by creating the following as your unprivileged user:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: demo
      namespace: default
    spec:
      serviceAccountName: pspbot
      containers:
      - name: demo
        image: centos:7
        command: ["sleep", "10000"]
    ```

    This time, the creation should succeed.

8.  Clean up most of these objects:

    ```bash
    kubectl delete pod demo
    kubectl delete ClusterRoleBinding pspbinding
    kubectl delete ClusterRole psprole
    kubectl delete PodSecurityPolicy psp
    ```

9.  The PodSecurityPolicy we created above completely nullifies the effect of PSPs; we would virtually never make such a grant if we wanted to actually take advantage of this security feature. Let's create a more useful PSP, which forbids privileged containers in pods and requires all containerized processes to run as a non-root user:

    ```yaml
    apiVersion: policy/v1beta1
    kind: PodSecurityPolicy
    metadata:
      name: noroot
      annotations:
        seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
    spec:
      privileged: false
      allowPrivilegeEscalation: false
      allowedCapabilities:
      - '*'
      volumes:
      - '*'
      hostNetwork: true
      hostPorts:
      - min: 0
        max: 65535
      hostIPC: true
      hostPID: true
      runAsUser:
        rule: 'MustRunAsNonRoot'
      seLinux:
        rule: 'RunAsAny'
      supplementalGroups:
        rule: 'RunAsAny'
      fsGroup:
        rule: 'RunAsAny'
    ```

10. Recreate an appropriate ClusterRole and ClusterRoleBinding to grant your `pspbot` service account the right to use this new `noroot` PSP, similar to what you did above.

11. Create the same pod you did above, again as your non-admin UCP user. Container creation will get stuck in a `CreateContainerConfigError` state, as the centos container is not allowed to start as root.

12. Try and create your pod again, but this time run your containerized process as an unprivileged user:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: demo
      namespace: default
    spec:
      serviceAccountName: pspbot
      securityContext:
        runAsUser: 1000
      containers:
      - name: demo
        image: centos:7
        command: ["sleep", "10000"]
    ```

    This time the pod creation succeeds, since it respects the constraints imposed on pod creation by the available PSP.

13. Delete the pods you just created to clean up.

14. Finally, re-create the clusterRoleBinding that removes the requirement for podSecurityPolicy definitions, just so we don't have to manage this in future exercises:

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: ucp:all:privileged-psp-role
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: privileged-psp-role
    subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: Group
      name: system:authenticated
    - apiGroup: rbac.authorization.k8s.io
      kind: Group
      name: system:serviceaccounts
    ```

## Conclusion

While pods and containers are designed to be aggressively isolated from each other and their underlying hosts by default, a strong podSecuriyPolicy helps ensure that users are proactively following security best practices, such as not running as root and not running privileged containers.
