{%- from 'ecs/settings.sls' import ecs with context %}

{% set instance_id = salt['cmd.run']('curl -s http://169.254.169.254/latest/meta-data/instance-id') %}
{% set users = salt['user.list_users']() %}
{% if 'vagrant' not in users %}
ecs_awscli:
  pkg.installed:
    - pkgs:
        - awscli
        - jq

create_instance_tags:
  cmd.run:
    - name: aws ec2 create-tags --resources {{ instance_id }} --tags Key=Salt_ID,Value={{ grains['id'] }} --region {{ grains['region'] }}
    - unless: aws ec2 describe-tags --filters "Name=resource-id,Values={{ instance_id }}" --region {{ grains['region'] }} | jq -M -e '.Tags[] | select(.Key | contains("Salt_ID"))'

create_service_tags:
  cmd.run:
    - name: aws ec2 create-tags --resources {{ instance_id }} --tags Key=Service,Value=ecs-{{ grains['env'] }} Key=Product,Value=container-hosting --region {{ grains['region'] }}
    - unless: aws ec2 describe-tags --filters "Name=resource-id,Values={{ instance_id }}" --region {{ grains['region'] }} | jq -M -e '.Tags[] | select(.Key | contains("Product"))'
{% endif %}

ecs_iam_role:
  sysctl.present:
    - name: net.ipv4.conf.all.route_localnet
    - value: 1

metadata-nat-1:
  iptables.append:
    - table: nat
    - family: ipv4
    - chain: PREROUTING
    - target: DNAT
    - destination: 169.254.170.2
    - to-destination: 127.0.0.1:51679
    - dport: 80
    - proto: tcp
    - save: True

metadata-nat-2:
  iptables.append:
    - table: nat
    - family: ipv4
    - chain: OUTPUT
    - match: tcp
    - target: REDIRECT
    - destination: 169.254.170.2
    - to-ports: 51679
    - dport: 80
    - proto: tcp
    - save: True

{% if grains['oscodename'] == 'trusty' %}
amazon/amazon-ecs-agent:
  dockerng.image_present:
    - force: True

ecs:
  dockerng.running:
    - image: amazon/amazon-ecs-agent
    - binds:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/log/ecs/:/log
      - /var/lib/ecs/data:/data
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
      - /var/run/docker/execdriver/native:/var/lib/docker/execdriver/native:ro
    - environment:
      - ECS_LOGLEVEL: debug
      - ECS_CLUSTER: {{ ecs.cluster_name }}
      - ECS_DATADIR: /data/
      - ECS_ENGINE_AUTH_TYPE: docker
      - ECS_AVAILABLE_LOGGING_DRIVERS: '["fluentd","json-file"]'
    - ports:
      - "51678/tcp"
    - port_bindings:
      - "51678:51678/tcp"
{% endif %}

{% if grains['oscodename'] == 'xenial' %}
amazon/amazon-ecs-agent:{{ ecs.tag }}:
  dockerng.image_present:
    - force: True

etc_default_amazon-ecs-agent:
  file.managed:
    - name: /etc/default/amazon-ecs-agent
    - source: salt://ecs/templates/amazon-ecs-agent
    - template: jinja

amazon-ecs-agent:
  file.managed:
    - name: /etc/systemd/system/amazon-ecs-agent.service
    - source: salt://ecs/files/amazon-ecs-agent.service
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: /etc/systemd/system/amazon-ecs-agent.service
  service.running:
    - enable: True
    - require:
      - dockerng: amazon/amazon-ecs-agent:{{ ecs.tag }}
      - file: /var/log/ecs-agent.log
    - watch:
      - dockerng: amazon/amazon-ecs-agent:{{ ecs.tag }}
      - file: /etc/systemd/system/amazon-ecs-agent
{% endif %}
