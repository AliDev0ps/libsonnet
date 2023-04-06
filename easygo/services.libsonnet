local k = import "github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet";

{
  local deployment = k.apps.v1.deployment,
  local container = k.core.v1.container,
  local port = k.core.v1.containerPort,
  local service = k.core.v1.service,
  local ingress = k.networking.v1.ingress,
  // deployment and container name
  local name = $._config.name,

  container::
    local containerPorts = std.flatMap(function(obj) [
        port.new(obj.name, obj.number)
      ], $._config.ports);

    container.new(name, $._images) +
    container.withPorts(containerPorts) +
    container.withArgs($._containers.args) +
    container.withEnv($._containers.env) +
    (if $._resources.enable then
      k.util.resourcesRequests($._resources.requests.cpu, $._resources.requests.memory) +
      k.util.resourcesLimits($._resources.limits.cpu, $._resources.limits.memory) else {}) +
    (if $._podProbe.enable then
      (if $._podProbe.startup.enable then
        container.mixin.startupProbe.tcpSocket.withPort($._podProbe.tcpSocketPort) +
        container.mixin.startupProbe.withFailureThreshold($._podProbe.startup.FailureThreshold) +
        container.mixin.startupProbe.withPeriodSeconds($._podProbe.startup.PeriodSeconds) else {}) +
      (if $._podProbe.liveness.enable then
        container.mixin.livenessProbe.tcpSocket.withPort($._podProbe.tcpSocketPort) +
        container.mixin.livenessProbe.withFailureThreshold($._podProbe.liveness.FailureThreshold) +
        container.mixin.livenessProbe.withInitialDelaySeconds($._podProbe.liveness.InitialDelaySeconds) +
        container.mixin.livenessProbe.withPeriodSeconds($._podProbe.liveness.PeriodSeconds) +
        container.mixin.livenessProbe.withTimeoutSeconds($._podProbe.liveness.TimeoutSeconds) else {}) +
      (if $._podProbe.readiness.enable then
        container.mixin.readinessProbe.httpGet.withPath($._podProbe.httpGetPath) +
        container.mixin.readinessProbe.httpGet.withPort($._podProbe.httpGetPort) +
        container.mixin.readinessProbe.withFailureThreshold($._podProbe.readiness.FailureThreshold) +
        container.mixin.readinessProbe.withInitialDelaySeconds($._podProbe.readiness.InitialDelaySeconds) +
        container.mixin.readinessProbe.withPeriodSeconds($._podProbe.readiness.PeriodSeconds) +
        container.mixin.readinessProbe.withTimeoutSeconds($._podProbe.readiness.TimeoutSeconds) else {})
    else {}),

  deployment:
    deployment.new(name, $._config.replicas, [$.container]) +
    deployment.mixin.metadata.withLabels($._config.metadata.labels) +
    deployment.mixin.spec.selector.withMatchLabelsMixin($._config.metadata.labels) +
    deployment.mixin.spec.template.metadata.withLabelsMixin($._config.metadata.labels) +
    deployment.mixin.spec.withProgressDeadlineSeconds($._deploy.progressDeadlineSeconds) +
    deployment.mixin.spec.withRevisionHistoryLimit($._deploy.revisionHistoryLimit) +
    deployment.mixin.spec.template.spec.securityContext.withRunAsGroup($._deploy.securityContext.runAsGroup) +
    deployment.mixin.spec.template.spec.securityContext.withRunAsNonRoot($._deploy.securityContext.runAsNonRoot) +
    deployment.mixin.spec.template.spec.securityContext.withRunAsUser($._deploy.securityContext.runAsUser) +
    (if $._promScrape.enable then
      deployment.mixin.spec.template.metadata.withAnnotations($._promScrape.annotations) else {}) +
    (if $._deploy.imagePullSecrets.enable then
      deployment.mixin.spec.template.spec.withImagePullSecrets($._deploy.imagePullSecrets.secret) else {}),

  serviceFor(deployment)::
    local servicePort = k.core.v1.servicePort;

    // filter ports
    local validPorts = std.filter(
      function(obj) 
        obj.isSvcPort != false, $._config.ports
    );

    local ports = [
      servicePort.newNamed(
        name=port.name,
        port=port.number,
        targetPort=port.name,
      ) +
      servicePort.withProtocol('TCP')  // default TCP
      for port in validPorts
    ];

    local labels = {
      [x]: deployment.spec.template.metadata.labels[x]
      for x in std.objectFields(deployment.spec.template.metadata.labels)
    };

    service.new(
      $._config.svcName,  // name
      labels,  // selector
      ports,
    ) +
    service.mixin.metadata.withLabels(deployment.metadata.labels),

  service:
    $.serviceFor(self.deployment),

  // Create ingress
  ingressFor(service)::
    local backendPoints = k.networking.v1.ingressBackend;
    local ingressRule = k.networking.v1.ingressRule;
    local ingressTls = k.networking.v1.ingressTLS;

    local labels = {
      [x]: service.metadata.labels[x]
      for x in std.objectFields(service.metadata.labels)
    };

    // the paths with rules
    local ingressPaths(paths) = std.map(function(obj) {
        backend:
          backendPoints.mixin.service.withName(obj.svcName) +
          (if std.isNumber(obj.svcPort) then
            backendPoints.mixin.service.port.withNumber(obj.svcPort)
          else backendPoints.mixin.service.port.withName(obj.svcPort)),
        path: obj.path,
        pathType: obj.pathType,
        }, paths);

    local rules = std.flatMap(function(obj) [
        ingressRule.withHost(obj.hosts) +
        ingressRule.mixin.http.withPaths(ingressPaths(obj.paths)),
      ], $._ingress.rules);

    local tls = std.flatMap(function(obj) [
        ingressTls.withHosts(obj.hosts) +
        ingressTls.withSecretName(obj.secret),
      ], $._ingress.security.tls);

    ingress.new($._config.ingName) +
    ingress.mixin.metadata.withLabels(labels) +
    ingress.mixin.metadata.withAnnotations($._ingress.annotations) +
    ingress.mixin.spec.withIngressClassName($._ingress.className) +
    ingress.mixin.spec.withRules(rules) +
    if $._ingress.security.enable then
      ingress.mixin.spec.withTls(tls) else {},

  ingress:
    if $._ingress.enable then
      $.ingressFor(self.service),

}
