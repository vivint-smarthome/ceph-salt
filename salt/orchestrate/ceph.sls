# vi: set ft=yaml.jinja :

key_setup:
  salt.state:
    - tgt: 'roles:ceph-mon'
    - tgt_type: grain
    - sls: ceph.keyring

mon_setup:
  salt.state:
    - tgt: 'roles:ceph-mon'
    - tgt_type: grain
    - sls: ceph.mon

osd_setup:
  salt.state:
    - tgt: 'roles:ceph-osd'
    - tgt_type: grain
    - sls: ceph.osd
    - require:
      - salt: mon_setup
