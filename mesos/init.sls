{% from "mesos/map.jinja" import mesos as mesos_map %}
{% set mesos = salt['pillar.get']('mesos') %}

mesos-repository:
  pkgrepo.managed:
    - name: deb http://repos.mesosphere.io/ubuntu/ trusty main
    - file: /etc/apt/sources.list.d/mesos.list
    - keyid: E56151BF
    - keyserver: keyserver.ubuntu.com

mesos:
  pkg.installed:
    - name: {{ mesos_map.package }}
{% if mesos.get('version') %}
    - version: {{ mesos.version }}
{% endif %}
    - install_recommends: False
    - require:
      - pkgrepo: mesos-repository

/etc/default/mesos:
  file.absent:
    - require:
      - pkg: mesos


{% for service_name, service in mesos.services.iteritems() %}
{% set service_map = mesos_map[service_name] %}

/etc/default/{{ service_map.service }}:
  file.managed:
    - source: salt://mesos/files/default
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - defaults:
        service: {{ service }}
    - require:
      - pkg: mesos
    - watch_in:
      - service: {{ service_map.service }}

{% for conf in service.conf %}
{{ service_map.conf_dir }}/{{ conf }}:
  file.managed:
    - contents_pillar: mesos:services:{{ service_name }}:conf:{{ conf }}
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: mesos
    - require_in:
      - file: {{ service_map.service }}-conf
    - watch_in:
      - service: {{ service_map.service }}
{% endfor %}

{{ service_map.service }}-conf:
  file.directory:
    - name: {{ service_map.conf_dir }}
    - clean: True
    - require:
      - pkg: mesos

{{ service_map.service }}:
  service.running:
    - require:
      - pkg: mesos

{% endfor %}
