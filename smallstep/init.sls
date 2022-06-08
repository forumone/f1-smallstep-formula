{% import "smallstep/map.jinja" as smallstep %}

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
    - env:
        - STEP_SSH_TEAM: {{ smallstep.team }}
        - STEP_SSH_TOKEN: {{ smallstep.token }}
        - STEP_SSH_TAGS: "Type=Utility Project={{ smallstep.project }} Client={{ smallstep.client }}"
        - STEP_SSH_HOSTNAME: {{ smallstep.hostname }}
        - STEP_SSH_BASTION: {{ smallstep.bastion }}
    - name: bash ./ssh-host.sh
    - unless: test -e /bin/step
    - output_loglevel: quiet
    - hide_output: False
    - creates: /bin/step
#    - success_retcodes: 

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
        user: "ssh-{{ smallstep.client }}-{{ user }}"
    - require:
      - /etc/ssh/scripts/

{{ user }}_ssh_match_user:
  file.append:
    - name: /etc/ssh/sshd_config
    - text: |
        Match User {{ user }}
          AuthorizedPrincipalsCommandUser root
          AuthorizedPrincipalsCommand /etc/ssh/scripts/{{ user }}-okta-sync.sh
    - require: 
      - /etc/ssh/scripts/{{ user }}-okta-sync.sh
    - onlyif:
      - fun: file.search
        path: /etc/ssh/sshd_config
        pattern: 'autogenerated by step'

sshd_{{ user }}_reload:
  service.running:
    - name: sshd
    - reload: True
    - watch:
      - {{ user }}_ssh_match_user
  {% endfor %}
{% endif %}

{% if pillar.node is defined %}
  {% for site, name in pillar.node.sites.items() %}
  {% set user = name.user %}

/etc/ssh/scripts/{{ user }}-okta-sync.sh:
  file.managed:
    - source: salt://smallstep/files/okta-sync.sh
    - template: jinja
    - user: root
    - group: root
    - mode: 700
    - context:
        user: "ssh-{{ smallstep.client }}-{{ user }}"
    - require:
      - /etc/ssh/scripts/

{{ user }}_ssh_match_user:
  file.append:
    - name: /etc/ssh/sshd_config
    - text: |
        Match User {{ user }}
          AuthorizedPrincipalsCommandUser root
          AuthorizedPrincipalsCommand /etc/ssh/scripts/{{ user }}-okta-sync.sh
    - require:
      - /etc/ssh/scripts/{{ user }}-okta-sync.sh
    - onlyif:
      - fun: file.search
        path: /etc/ssh/sshd_config
        pattern: 'autogenerated by step'

sshd_{{ user }}_reload:
  service.running:
    - name: sshd
    - reload: True
    - watch:
      - {{ user }}_ssh_match_user
  {% endfor %}
{% endif %}