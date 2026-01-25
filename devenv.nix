{ pkgs, lib, config, inputs, ... }:

let
  customPython3 = pkgs.python3.withPackages(ps: [
    ps.python-lsp-server
  ]);
  zshell = pkgs.writeShellScriptBin "zshell" ''
    set -e
    echo "[initializing zellij-devenv...]"
    cd ${config.devenv.root} && exec ${pkgs.devenv}/bin/devenv shell --quiet
  '';
in {
  # https://devenv.sh/basics/
  env.SESSION_NAME = "langnet-tools";
  env.GIT_EXTERNAL_DIFF = "${pkgs.difftastic}/bin/difft";
  # env.GREET = "${config.name}";

  # env.PULUMI_CONFIG_PASSPHRASE = "";

  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.difftastic
    pkgs.shellcheck

    # pkgs.pulumi-bin
    # pkgs.hcloud
    # pkgs.ansible

    pkgs.opencode
    # pkgs.envsubst
    
    # pkgs.docker
    # pkgs.oras
    # pkgs.skopeo
    # pkgs.regctl

    # pkgs.s5cmd
    # pkgs.ssh-to-age

    # pkgs.black
    # pkgs.mypy
    # pkgs.nil

    pkgs.envsubst
    pkgs.devenv
    pkgs.process-compose
    pkgs.just
    pkgs.netcat
    pkgs.openssl

    pkgs.nushell

    zshell
    pkgs.zellij
    pkgs.starship

  ];

  # difftastic.enable = true;

  # https://devenv.sh/languages/
  languages.python.enable = true;
  languages.python.package = customPython3;
  languages.python.venv.enable = true;
  # languages.python.venv.requirements = builtins.readFile ./dreamcloud/requirements.txt;

  # languages.go.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  # scripts.hello.exec = ''
  #   echo hello from $GREET
  # '';

  scripts.zell.exec = ''
    #!/usr/bin/env bash

    # 1. CLEANUP: If the session exists but is "EXITED", delete it.
    if zellij list-sessions --no-formatting 2>/dev/null | grep "^$SESSION_NAME" | grep -q "EXITED"; then
        echo "Resurrecting $SESSION_NAME from a clean state..."
        zellij delete-session "$SESSION_NAME"
    fi

    # 2. PROMPT FIX: Neutralize the "Crazy Brackets"
    unset PROMPT_COMMAND
    export PS1="\$ "

    # 3. LAUNCH: Create or Attach with the 'compact' layout
    zellij options \
      --show-startup-tips false \
      --show-release-notes false \
      --default-shell zshell \
      --attach-to-session true \
      --session-name "$SESSION_NAME"
  '';

  enterShell = ''
    unset PS1
    eval $(starship init bash)
    source $DEVENV_STATE/venv/bin/activate
    export VIRTUAL_ENV_PROMPT="$SESSION_NAME"
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
