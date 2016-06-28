# vi: set ft=yaml.jinja :

{% import tpldir + '/global_vars.jinja' as conf with context -%}

include:
  - .repo

ceph:
  pkg.installed:
    - require:
      - pkgrepo: ceph_repo

{{ conf.conf_file }}:
  file.managed:
    - template: jinja
    - source: salt://{{ tpldir }}/etc/ceph/ceph.conf
    - context:
        cephdir: {{tpldir | json}}
    - user: root
    - group: root
    - mode: '0644'
    - makedirs: True
    - require:
      - pkg: ceph

cp.push {{ conf.conf_file }}:
  module.wait:
    - name: cp.push
    - path: {{ conf.conf_file }}
    - watch:
      - file: {{ conf.conf_file }}
