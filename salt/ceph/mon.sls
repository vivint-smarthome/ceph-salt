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

{{ conf.mon_keyring}}:
  file.managed:
    - source: salt://{{ pillar.ceph.config_leader }}{{ conf.mon_keyring }}

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
                   --add {{ mon_grains[conf.host_grain] }} {{ mon_grains[conf.mon_interface]['inet'][0]['address'] }} \
                   {%- endfor %}
                   --fsid {{ conf.fsid }} {{ monmap }}
    - unless: test -f {{ monmap }}
    - require:
      - file: {{ conf.conf_file }}


populate_mon:
  cmd.run:
    - name: |
        ceph-mon --cluster {{ conf.cluster }} \
                 --mkfs -i {{ conf.host }} \
                 --monmap {{ monmap }} \
                 --keyring {{ secret }}
    - unless: test -f /var/lib/ceph/mon/{{ conf.cluster }}-{{ conf.host }}
    - require:
      - file: {{ conf.conf_file }}
      - cmd: gen_mon_map
      - cmd: import_keyring

start_mon:
  cmd.run:
    {% if grains.os == "CentOS" %}
    - name: /etc/init.d/ceph start mon.{{ conf.host }}
    - unless: /etc/init.d/ceph status mon.{{ conf.host }}
    {% else %}
    - name: start ceph-mon id={{ conf.host }} cluster={{ conf.cluster }}
    - unless: status ceph-mon id={{ conf.host }} cluster={{ conf.cluster }}
    {% endif %}
    - require:
      - cmd: populate_mon
      - file: start_mon
  file.managed:
    {% if grains.os == "CentOS" %}
    - name: /var/lib/ceph/mon/{{ conf.cluster }}-{{ conf.host }}/sysvinit
    {% else %}
    - name: /var/lib/ceph/mon/{{ conf.cluster }}-{{ conf.host }}/upstart
    {% endif %}
    - contents: ""

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

