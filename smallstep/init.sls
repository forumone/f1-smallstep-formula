{% from "smallstep/map.jinja" import bastion, project, suffix, client, team, token with context %}

/opt/smallstep/install:
  file.directory:
    - user: root
    - group: root
    - makedirs: True
    - mode: 2700

smallstep_installer:
  file.managed:
    - name: /opt/smallstep/install/ssh-host.sh
    - source: https://files.smallstep.com/ssh-host.sh
    - skip_verify: True

install_smallstep:
  cmd.run:
    - cwd: /opt/smallstep/install
    - name: bash ./ssh-host.sh --bastion {{ bastion }} --hostname "{{ project }}.{{ suffix }}" --tag "Type=utility" --tag "Project={{ project }}" --tag "Client={{ client }}" --team {{ team }} --token {{ token }}
    - unless: test -e /bin/step
    - stateful: True

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
    - stateful: True
    - context:
        user: "ssh-{{ client }}-{{ user }}"
    - require:
      - /etc/ssh/scripts/

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
    - require:
      - /etc/ssh/scripts/{{ user }}-okta-sync.sh
      - install_smallstep
    - order:
      - last

sshd_{{ user }}_reload:
  service.running:
    - name: sshd
    - reload: True
    - watch:
      - {{ user }}_ssh_match_user
  {% endfor %}
{% endif %}

{% if pillar.node.sites is defined %}
  {% for site, name in pillar.node.sites.items() %}
  {% set user = name.user %}

/etc/ssh/scripts/{{ user }}-okta-sync.sh:
  file.managed:
    - source: salt://smallstep/files/okta-sync.sh
    - template: jinja
    - user: root
    - group: root
    - mode: 700
    - stateful: True
    - context:
        user: "ssh-{{ client }}-{{ user }}"
    - require:
      - /etc/ssh/scripts/

{{ user }}_ssh_match_user:
  file.replace:
    - append_if_not_found: True
    - name: /etc/ssh/sshd_config
    - stateful: True
    - pattern: |
        Match User {{ user }}
          AuthorizedPrincipalsCommandUser root
          AuthorizedPrincipalsCommand /etc/ssh/scripts/{{ user }}-okta-sync.sh
    - repl: |
        Match User {{ user }}
          AuthorizedPrincipalsCommandUser root
          AuthorizedPrincipalsCommand /etc/ssh/scripts/{{ user }}-okta-sync.sh
    - require:
      - /etc/ssh/scripts/{{ user }}-okta-sync.sh
      - install_smallstep
    - order:
      - last

sshd_{{ user }}_reload:
  service.running:
    - name: sshd
    - reload: True
    - watch:
      - {{ user }}_ssh_match_user
  {% endfor %}
{% endif %}