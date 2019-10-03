Prometheus
==========

Prometheus is deployed in PHX in order to store and analyze various metrics
of the environment including CI jobs.

Since Prometheus actively crawls through discovered targets and CI jobs
are short-living, a push gateway was deployed to cache metrics for Prometheus.

Sending data from Jenkins jobs
------------------------------

The endpoint to send metrics to is https://prom-gw.apps.ovirt.org/

Access to the endpoint is protected using certificate authentication.
A client needs to supply a certificate with each request.

Required data is available as Jenkins credentials:

| credential name in Jenkins | description        |
| -------------------------- | ------------------ |
| prom-ca                    | CA certificate     |
| prom-crt                   | client certificate |
| prom-key                   | client private key |

To send data add these credentials to a job and use the resulting environment
variables as respective arguments for the HTTP client.

Here's a simple curl example that will send the test data to Prometheus:

    echo "build_number $BUILD_NUMBER" | curl --data-binary @- --cacert $prom_ca --cert $prom_crt --key $prom_key https://prom-gw.apps.ovirt.org/metrics/job/$JOB_NAME

In this case, the build number is sent as the `build_number` metric
and the job name is added as a label for future analysis.
The certificate and key are provided by Jenkins as credentials.

Check out the [official docs](https://prometheus.io/docs/instrumenting/pushing/) for more examples.

Accessing and visualising the data
----------------------------------

The instance is deployed in OpenShift, data can be viewed and analyzed
in [Prometheus](https://prometheus-openshift-metrics.apps.ovirt.org/) directly or through [Kibana](https://grafana-openshift-grafana.apps.ovirt.org/)
