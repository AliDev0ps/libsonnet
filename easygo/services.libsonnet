local k = import "github.com/grafana/jsonnet-libs/ksonnet-util/kausal.libsonnet";

{
  local deployment = k.apps.v1.deployment,
  local container = k.core.v1.container,
  local port = k.core.v1.containerPort,
  local service = k.core.v1.service,

  // deployment and container name
  local name = $._config.name,

  container::
    container.new(name, $._images) +
    container.withPorts([port.new("server", $._config.port.server), port.new("metrics", $._config.port.metrics)]) +
    container.withArgs($._containers.args) +
    container.withEnv($._containers.env) +
    if $._resources.enable then
      k.util.resourcesRequests($._resources.requests.cpu, $._resources.requests.memory) +
      k.util.resourcesLimits($._resources.limits.cpu, $._resources.limits.memory) else {} +
    if $._podProbe.enable then
      container.mixin.startupProbe.tcpSocket.withPort('server') +
      container.mixin.startupProbe.withFailureThreshold($._podProbe.startup.FailureThreshold) +
      container.mixin.startupProbe.withPeriodSeconds($._podProbe.startup.PeriodSeconds) +
      container.mixin.livenessProbe.tcpSocket.withPort('server') +
      container.mixin.livenessProbe.withFailureThreshold($._podProbe.liveness.FailureThreshold) +
      container.mixin.livenessProbe.withInitialDelaySeconds($._podProbe.liveness.InitialDelaySeconds) +
      container.mixin.livenessProbe.withPeriodSeconds($._podProbe.liveness.PeriodSeconds) +
      container.mixin.livenessProbe.withTimeoutSeconds($._podProbe.liveness.TimeoutSeconds) +
      container.mixin.readinessProbe.httpGet.withPath('/actuator/health') +
      container.mixin.readinessProbe.httpGet.withPort('metrics') +
      container.mixin.readinessProbe.withFailureThreshold($._podProbe.readiness.FailureThreshold) +
      container.mixin.readinessProbe.withInitialDelaySeconds($._podProbe.readiness.InitialDelaySeconds) +
      container.mixin.readinessProbe.withPeriodSeconds($._podProbe.readiness.PeriodSeconds) +
      container.mixin.readinessProbe.withTimeoutSeconds($._podProbe.readiness.TimeoutSeconds) else {},

  deployment:
    deployment.new(name, $._config.replicas, [$.container]) +
    deployment.mixin.metadata.withLabels($._config.metadata.labels) +
    deployment.mixin.spec.withProgressDeadlineSeconds($._deploy.progressDeadlineSeconds) +
    deployment.mixin.spec.withRevisionHistoryLimit($._deploy.revisionHistoryLimit) +
    deployment.mixin.spec.template.spec.securityContext.withRunAsGroup($._deploy.securityContext.runAsGroup) +
    deployment.mixin.spec.template.spec.securityContext.withRunAsNonRoot($._deploy.securityContext.runAsNonRoot) +
    deployment.mixin.spec.template.spec.securityContext.withRunAsUser($._deploy.securityContext.runAsUser) +
    if $._promScrape.enable then
      deployment.mixin.spec.template.metadata.withAnnotations($._promScrape.annotations) else {} +
    if $._deploy.imagePullSecrets.enable then
      deployment.mixin.spec.template.spec.withImagePullSecrets($._deploy.imagePullSecrets.secret) else {},

  serviceFor(deployment)::
    local servicePort = k.core.v1.servicePort;

    local ports = [
      servicePort.newNamed(
        name='http',
        port=$._config.port.server,
        targetPort='server',
      ) +
      servicePort.withProtocol('TCP'),  // default TCP
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
    service.mixin.metadata.withLabels({ name: deployment.metadata.name }),

  service:
    $.serviceFor(self.deployment),
}
