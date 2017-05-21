{% set p    = pillar.get('ecs', {}) %}
{% set pc   = p.get('config', {}) %}
{% set g    = grains.get('ecs', {}) %}
{% set gc   = g.get('config', {}) %}

{%- set ecs = {} %}
{%- do ecs.update({
  'cluster_name'              : p.get('cluster_name', 'cluster_0'),
  'logfile'                   : p.get('logfile', '/var/log/ecs-agent.log'),
  'loglevel'                  : p.get('loglevel', 'debug'),
  'datadir'                   : p.get('datadir', '/data'),
  'engine_auth_type'          : p.get('engine_auth_type', 'docker'),
  'available_logging_drivers' : p.get('available_logging_drivers', '["fluentd","json-file"]'),
  'engine_auth_data'          : p.get('engine_auth_data', 'auth_data'),
  'port'                      : p.get('port', '51678'),
  'tag'                       : p.get('tag', 'latest')
  }) %}
