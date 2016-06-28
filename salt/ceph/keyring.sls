include:
  - .ceph

{% if grains.id == pillar.ceph.config_leader %}
{% import tpldir + '/global_vars.jinja' as conf with context -%}

{{ conf.admin_keyring }}:
  cmd.run:
    - name: |
        ceph-authtool --cluster {{ conf.cluster }} \
                      --create-keyring {{ conf.admin_keyring }} \
                      --gen-key -n client.admin \
                      --set-uid=0 \
                      --cap mon 'allow *' \
                      --cap osd 'allow *' \
                      --cap mds 'allow'
    - unless: test -f /var/lib/ceph/mon/{{ conf.cluster }}-{{ conf.host }}/keyring || test -f {{ conf.admin_keyring }}
    - require:
      - pkg: ceph
      - file: {{ conf.conf_file }}
  module.run:
    - name: cp.push
    - path: {{ conf.admin_keyring }}
    - watch:
      - cmd: {{ conf.admin_keyring }}

{{ conf.mon_keyring }}:
  cmd.run:
    - name: |
        ceph-authtool --cluster {{ conf.cluster }} \
                      --create-keyring {{ conf.mon_keyring }} \
                      --gen-key -n mon. \
                      --cap mon 'allow *'
    - require:
      - file: {{ conf.conf_file }}
      - pkg: ceph
  module.run:
    - name: cp.push
    - path: {{ conf.mon_keyring }}
    - watch:
      - cmd: {{ conf.mon_keyring }}
{% endif %}

