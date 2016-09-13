# vi: set ft=yaml.jinja :

{% set mydir = "./ceph" %} # work around nasty regression!!!
{% import mydir + '/global_vars.jinja' as conf with context -%}

include:
  - .repo

ceph:
  pkg.installed:
    - require:
      - pkgrepo: ceph_repo

{{ conf.conf_file }}:
  file.managed:
    - template: jinja
    - source: salt://{{ mydir }}/etc/ceph/ceph.conf
    - context:
        cephdir: {{mydir | json}}
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
