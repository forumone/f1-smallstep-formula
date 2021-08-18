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