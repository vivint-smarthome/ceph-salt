# vi: set ft=yaml.jinja :

{% import tpldir + '/global_vars.jinja' as conf with context -%}
{% set ip = salt['network.ip_addrs'](conf.mon_interface)[0] -%}
{% set secret = '/var/lib/ceph/tmp/' + conf.cluster + '.mon.keyring' -%}
{% set monmap = '/var/lib/ceph/tmp/' + conf.cluster + 'monmap' -%}

include:
  - .ceph

{{ conf.admin_keyring }}:
  file.managed:
    - source: salt://{{ pillar.ceph.config_leader }}{{ conf.admin_keyring }}
    - group: ceph
    - mode: 640
    - require:
      - pkg: ceph

{{ conf.mon_keyring}}:
  file.managed:
    - source: salt://{{ pillar.ceph.config_leader }}{{ conf.mon_keyring }}
    - group: ceph
    - mode: 640
    - require:
      - pkg: ceph

trigger_secret_gen_if_missing:
  cmd.run:
    - name: "echo Regenerating mon node keyring"
    - unless: |
        [ -f {{secret}} ]

import_keyring:
  cmd.wait:
    - name: |
        cp {{conf.mon_keyring}} {{ secret }}
        ceph-authtool --cluster {{ conf.cluster }} {{ secret }} \
                      --import-keyring {{ conf.admin_keyring }}
    - unless: ceph-authtool {{ secret }} --list | grep '^\[client.admin\]'
    - user: ceph
    - watch:
      - file: {{conf.admin_keyring}}
      - file: {{conf.mon_keyring}}
      - cmd: trigger_secret_gen_if_missing
    - require:
      - file: {{ conf.conf_file }}

gen_mon_map:
  cmd.run:
    - name: |
        monmaptool --cluster {{ conf.cluster }} \
                   --create \
                   {%- for mon, mon_grains in salt['mine.get'](pillar.ceph.mon.target, 'grains.items', pillar.ceph.mon.expr_form).items() | sort %}
                   --add {{ mon_grains[conf.host_grain] }} {{ mon_grains['ip4_interfaces'][conf.mon_interface][0] }} \
                   {%- endfor %}
                   --fsid {{ conf.fsid }} {{ monmap }}
    - unless: test -f {{ monmap }}
    - user: ceph
    - require:
      - file: /var/lib/ceph/tmp
      - file: {{ conf.conf_file }}

/var/lib/ceph/tmp:
  file.directory:
    - user: ceph
    - group: ceph
    - mode: 775
    - require:
      - pkg: ceph

populate_mon:
  cmd.run:
    - name: |
        ceph-mon --cluster {{ conf.cluster }} \
                 --mkfs -i {{ conf.host }} \
                 --monmap {{ monmap }} \
                 --keyring {{ secret }}
    - unless: test -f /var/lib/ceph/mon/{{ conf.cluster }}-{{ conf.host }}
    - user: ceph
    - require:
      - file: {{ conf.conf_file }}
      - file: /var/lib/ceph/tmp
      - cmd: gen_mon_map
      - cmd: import_keyring

{% if grains.os == "CentOS" %}
start_mon:
  service.running:
    - name: ceph-mon@{{conf.host}}
    - enable: True
    - require:
      - cmd: populate_mon
  cmd.wait:
    - name: echo started
    - watch:
      - service: start_mon
{% else %}
start_mon:
  cmd.run:
    - name: start ceph-mon id={{ conf.host }} cluster={{ conf.cluster }}
    - unless: status ceph-mon id={{ conf.host }} cluster={{ conf.cluster }}
    - require:
      - cmd: populate_mon
      - file: start_mon
  file.managed:
    - name: /var/lib/ceph/mon/{{ conf.cluster }}-{{ conf.host }}/upstart
    - contents: ""
{% endif %}


osd_keyring_wait:
  cmd.wait:
    - name: while ! test -f {{ conf.bootstrap_osd_keyring }}; do sleep 1; done
    - timeout: 30
    - watch:
      - cmd: start_mon

cp.push {{ conf.bootstrap_osd_keyring }}:
  module.wait:
    - name: cp.push
    - path: {{ conf.bootstrap_osd_keyring }}
    - watch:
      - cmd: osd_keyring_wait

