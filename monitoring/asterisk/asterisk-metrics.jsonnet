local asterisk = import 'asterisk-mixin/mixin.libsonnet';

asterisk {
  _config+:: {
    namespace: 'asterisk-metrics',
    prometheusSelector: '{job="asterisk"}',
  },
}
