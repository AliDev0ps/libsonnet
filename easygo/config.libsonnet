{
    _images+:: null,

    _promScrape+:: {
        enable: false,
        annotations: {
            "prometheus.io/path": "/actuator/prometheus",
            "prometheus.io/port": 8181,
            "prometheus.io/scrape": true,
        },
    },

    _containers+:: {
        args: [],
        env: [
            {
                name: 'TZ',
                value: 'GMT-8',
            },
            {
                name: 'JAVA_TOOL_OPTIONS',
                value: '-Xmx512m -Xmx512m',
            },
        ],
    },

    _resources+:: {
        enable: true,
        requests: {
            cpu: '100m',
            memory: '512Mi',
        },
        limits: {
            cpu: '1000m',
            memory: '1Gi',
        },
    },

    _podProbe+:: {
        enable: false,
        startup: {
            FailureThreshold: 24,
            PeriodSeconds: 5,
        },
        liveness: {
            FailureThreshold: 5,
            PeriodSeconds: 10,
            InitialDelaySeconds: 3,
            TimeoutSeconds: 2,
        },
        readiness: {
            FailureThreshold: 11,
            PeriodSeconds: 5,
            InitialDelaySeconds: 5,
            TimeoutSeconds: 2,
        },
    },

    _deploy+:: {
        progressDeadlineSeconds: 120,
        revisionHistoryLimit: 20,
        imagePullSecrets: {
            enable: true,
            secret: 'acr-auth',
        },
        securityContext: {
            runAsUser: 65534,
            runAsGroup: 65534,
            runAsNonRoot: true,
        },
    },

    _config+:: {
        replicas: 1,
        port: {
            server: null,
            metrics: null,
        },
        name: null,
        svcName: null,
        metadata: {
            labels: {
                project: 'easygo',
            },
        },
    },
}
