{
    _images+:: null,

    _config+:: {
        replicas: 1,
        ports: [
            // {
            //     name: null,
            //     number: null,
            //     isSvcPort: false,
            // },
        ],
        name: null,  // deployment and container name
        svcName: null,
        ingName: null,
        metadata: {
            labels: {},
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
            enable: true,
            FailureThreshold: 24,
            PeriodSeconds: 5,
        },
        liveness: {
            enable: true,
            FailureThreshold: 5,
            PeriodSeconds: 10,
            InitialDelaySeconds: 3,
            TimeoutSeconds: 2,
        },
        readiness: {
            enable: true,
            FailureThreshold: 11,
            PeriodSeconds: 5,
            InitialDelaySeconds: 5,
            TimeoutSeconds: 2,
        },
        // ref: _config.ports[]
        tcpSocketPort: null,
        httpGetPort: null,
        httpGetPath: null,
    },

    _deploy+:: {
        progressDeadlineSeconds: 120,
        revisionHistoryLimit: 20,
        imagePullSecrets: {
            enable: false,
            secret: [
                { name: null },
            ],
        },
        securityContext: {
            runAsUser: 65534,
            runAsGroup: 65534,
            runAsNonRoot: true,
        },
    },

    _promScrape+:: {
        enable: false,
        annotations: {
            'prometheus.io/path': '/actuator/prometheus',
            'prometheus.io/port': '8181',
            'prometheus.io/scrape': 'true',
        },
    },

    _ingress+:: {
        enable: false,
        className: null,
        annotations: {
            // 'nginx.ingress.kubernetes.io/force-ssl-redirect': 'true',
        },
        rules: [
            {
                hosts: null,
                paths: [
                    // {
                    //     svcName: null,
                    //     svcPort: null,
                    //     path: '/',
                    //     pathType: 'Prefix',
                    // },
                ],
            },
        ],
        security: {
            enable: false,
            tls: [
                {
                    hosts: [],
                    secret: null,
                },
            ],
        },
    },
}
