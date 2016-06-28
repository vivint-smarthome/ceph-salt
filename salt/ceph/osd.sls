# vi: set ft=yaml.jinja :

{% import tpldir + '/global_vars.jinja' as conf with context -%}

include:
  - .ceph

{{ conf.bootstrap_osd_keyring }}:
  file.managed:
    - name: {{ conf.admin_keyring }}
    - source: salt://{{ pillar.ceph.config_leader }}{{ conf.admin_keyring }}

{% for dev in salt['pillar.get']('ceph:nodes:' + conf.host + ':devs') -%}
{% if dev -%}
{% set journal = salt['pillar.get']('ceph:nodes:' + conf.host + ':devs:' + dev + ':journal') -%}

disk_prepare {{ dev }}:
  cmd.run:
    - name: |
        ceph-disk prepare --cluster {{ conf.cluster }} \
                          --cluster-uuid {{ conf.fsid }} \
                          --fs-type xfs /dev/{{ dev }} /dev/{{ journal }}
    - unless: parted --script /dev/{{ dev }} print | grep 'ceph data'
    - require:
      - file: {{ conf.bootstrap_osd_keyring }}

disk_activate {{ dev }}1:
  cmd.run:
    - name: ceph-disk activate /dev/{{ dev }}1
    - onlyif: test -f {{ conf.bootstrap_osd_keyring }}
    - unless: ceph-disk list | egrep "/dev/{{ dev }}1.*active"
    - timeout: 10

{% endif -%}
{% endfor -%}

start-ceph-osd-all:
  cmd.run:
    {% if grains.os == "CentOS" %}
    - name: start ceph-osd-all
    - onlyif: initctl list | grep "ceph-osd-all stop/waiting"
    {% else %}
    - name: start ceph-osd-all
    - onlyif: initctl list | grep "ceph-osd-all stop/waiting"
    {% endif %}
