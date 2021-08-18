{% from "smallstep/map.jinja" import client, project with context %}

/etc/ssh/scripts/:
  file.directory:
    - user: root
    - group: root
    - makedirs: True
    - mode: 2700

{% if pillar.vhosts.sites is defined %}
  {% for site, name in pillar.vhosts.sites.items() %}
  {% set user = name.user %}

/etc/ssh/scripts/{{ user }}-okta-sync.sh:
  file.managed:
    - source: salt://smallstep/files/okta-sync.sh
    - template: jinja
    - user: root
    - group: root
    - mode: 700
    - context:
        user: "ssh-{{ client }}-{{ user }}"
    - require: /etc/ssh/scripts/

{{ user }}_ssh_match_user:
  file.replace:
    - append_if_not_found: True
    - name: /etc/ssh/sshd_config
    - pattern: |
        Match User {{ user }}
          AuthorizedPrincipalsCommandUser root
          AuthorizedPrincipalsCommand /etc/ssh/scripts/{{ user }}-okta-sync.sh
    - repl: |
        Match User {{ user }}
          AuthorizedPrincipalsCommandUser root
          AuthorizedPrincipalsCommand /etc/ssh/scripts/{{ user }}-okta-sync.sh
    -require: /etc/ssh/scripts/{{ user }}-okta-sync.sh

sshd_{{ user }}_reload:
  service.running:
    - name: sshd
    - reload: True
    - watch:
      - {{ user }}_ssh_match_user
  {% endfor %}
{% endif %}