# vi: set ft=yaml.jinja :

{% set oscodename = salt['config.get']('oscodename') -%}
{% set version = salt['pillar.get']('ceph:version') -%}

{% if grains.os == "CentOS" %}
/etc/pki/rpm-gpg/RPM-GPG-KEY-ceph.com:
  file.managed:
    - contents: |
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v1

        mQINBFX4hgkBEADLqn6O+UFp+ZuwccNldwvh5PzEwKUPlXKPLjQfXlQRig1flpCH
        E0HJ5wgGlCtYd3Ol9f9+qU24kDNzfbs5bud58BeE7zFaZ4s0JMOMuVm7p8JhsvkU
        C/Lo/7NFh25e4kgJpjvnwua7c2YrA44ggRb1QT19ueOZLK5wCQ1mR+0GdrcHRCLr
        7Sdw1d7aLxMT+5nvqfzsmbDullsWOD6RnMdcqhOxZZvpay8OeuK+yb8FVQ4sOIzB
        FiNi5cNOFFHg+8dZQoDrK3BpwNxYdGHsYIwU9u6DWWqXybBnB9jd2pve9PlzQUbO
        eHEa4Z+jPqxY829f4ldaql7ig8e6BaInTfs2wPnHJ+606g2UH86QUmrVAjVzlLCm
        nqoGymoAPGA4ObHu9X3kO8viMBId9FzooVqR8a9En7ZE0Dm9O7puzXR7A1f5sHoz
        JdYHnr32I+B8iOixhDUtxIY4GA8biGATNaPd8XR2Ca1hPuZRVuIiGG9HDqUEtXhV
        fY5qjTjaThIVKtYgEkWMT+Wet3DPPiWT3ftNOE907e6EWEBCHgsEuuZnAbku1GgD
        LBH4/a/yo9bNvGZKRaTUM/1TXhM5XgVKjd07B4cChgKypAVHvef3HKfCG2U/DkyA
        LjteHt/V807MtSlQyYaXUTGtDCrQPSlMK5TjmqUnDwy6Qdq8dtWN3DtBWQARAQAB
        tCpDZXBoLmNvbSAocmVsZWFzZSBrZXkpIDxzZWN1cml0eUBjZXBoLmNvbT6JAjgE
        EwECACIFAlX4hgkCGwMGCwkIBwMCBhUIAgkKCwQWAgMBAh4BAheAAAoJEOhKwsBG
        DzmUXdIQAI8YPcZMBWdv489q8CzxlfRIRZ3Gv/G/8CH+EOExcmkVZ89mVHngCdAP
        DOYCl8twWXC1lwJuLDBtkUOHXNuR5+Jcl5zFOUyldq1Hv8u03vjnGT7lLJkJoqpG
        l9QD8nBqRvBU7EM+CU7kP8+09b+088pULil+8x46PwgXkvOQwfVKSOr740Q4J4nm
        /nUOyTNtToYntmt2fAVWDTIuyPpAqA6jcqSOC7Xoz9cYxkVWnYMLBUySXmSS0uxl
        3p+wK0lMG0my/gb+alke5PAQjcE5dtXYzCn+8Lj0uSfCk8Gy0ZOK2oiUjaCGYN6D
        u72qDRFBnR3jaoFqi03bGBIMnglGuAPyBZiI7LJgzuT9xumjKTJW3kN4YJxMNYu1
        FzmIyFZpyvZ7930vB2UpCOiIaRdZiX4Z6ZN2frD3a/vBxBNqiNh/BO+Dex+PDfI4
        TqwF8zlcjt4XZ2teQ8nNMR/D8oiYTUW8hwR4laEmDy7ASxe0p5aijmUApWq5UTsF
        +s/QbwugccU0iR5orksM5u9MZH4J/mFGKzOltfGXNLYI6D5Mtwrnyi0BsF5eY0u6
        vkdivtdqrq2DXY+ftuqLOQ7b+t1RctbcMHGPptlxFuN9ufP5TiTWSpfqDwmHCLsT
        k2vFiMwcHdLpQ1IH8ORVRgPPsiBnBOJ/kIiXG2SxPUTjjEGOVgeA
        =/Tod
        -----END PGP PUBLIC KEY BLOCK-----


ceph_repo:
  pkgrepo.managed:
    - name: ceph
    - humanname: Ceph Repository
    - baseurl: http://download.ceph.com/rpm-{{pillar.ceph.version}}/el{{grains.osmajorrelease}}/$basearch/
    - gpgkey: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ceph.com
    - gpgcheck: 1
    - require:
       - file: /etc/pki/rpm-gpg/RPM-GPG-KEY-ceph.com
        
{% else %}
ceph_repo:
  pkgrepo.managed:
    - name: deb http://ceph.com/debian-{{ version }}/ {{ oscodename }} main
    - file: /etc/apt/sources.list.d/ceph.list
    - key_url: https://raw.github.com/ceph/ceph/master/keys/release.asc
{% endif %}
