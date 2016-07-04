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
    - name: |
        for ID in $(cat /var/lib/ceph/osd/ceph-*/whoami); do
          systemctl start ceph-osd@$ID
          systemctl enable ceph-osd@$ID
        done
    - unless: |
        for ID in $(cat /var/lib/ceph/osd/ceph-*/whoami); do
          systemctl status ceph-osd@$ID && systemctl is-enabled ceph-osd@$ID || exit 1
        done
        exit 0
    {% else %}
    - name: start ceph-osd-all
    - onlyif: initctl list | grep "ceph-osd-all stop/waiting"
    {% endif %}
