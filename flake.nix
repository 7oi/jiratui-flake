{
  description = "JiraTUI - A TUI for interacting with Atlassian Jira from your terminal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        jiratui = pkgs.python3Packages.buildPythonApplication rec {
          pname = "jiratui";
          version = "0.2.0";
          pyproject = true;

          src = pkgs.fetchFromGitHub {
            owner = "whyisdifficult";
            repo = "jiratui";
            rev = "v${version}";
            hash = "sha256-aS5AWTNoNzhtPs6kYPTxb7SseLQcTOPAtlvsvv2+ECI=";
          };

          # Patch the pyproject.toml to use setuptools instead of uv_build
          postPatch = ''
            substituteInPlace pyproject.toml \
              --replace 'requires = ["uv_build>=0.8.10,<0.9.0"]' 'requires = ["setuptools>=45", "wheel"]' \
              --replace 'build-backend = "uv_build"' 'build-backend = "setuptools.build_meta"'

            # Remove version constraints to avoid conflicts with nixpkgs versions
            substituteInPlace pyproject.toml \
              --replace 'click>=8.2.1' 'click' \
              --replace 'httpx>=0.28.1' 'httpx' \
              --replace 'pydantic-settings[yaml]>=2.10.1' 'pydantic-settings[yaml]' \
              --replace 'python-json-logger>=3.3.0' 'python-json-logger' \
              --replace 'textual[syntax]>=5.3.0' 'textual[syntax]'
          '';

          build-system = with pkgs.python3Packages; [
            setuptools
            wheel
          ];

          dependencies = with pkgs.python3Packages; [
            click
            httpx
            pydantic-settings
            python-json-logger
            textual
            pyyaml  # Required for pydantic-settings[yaml]
          ];

          # Remove the runtime deps check hook to avoid version conflicts
          removeBuildInputs = [ pkgs.python3Packages.pythonRuntimeDepsCheckHook ];

          # Skip tests since they require network access and API credentials
          doCheck = false;

          # Disable dependency version checking
          pythonCatchConflicts = false;

          pythonImportsCheck = [ "jiratui" ];

          meta = with pkgs.lib; {
            description = "A TUI for interacting with Atlassian Jira from your terminal";
            homepage = "https://jiratui.sh";
            changelog = "https://github.com/whyisdifficult/jiratui/blob/main/CHANGELOG.md";
            license = licenses.mit;
            maintainers = with maintainers; [ ];
            mainProgram = "jiratui";
          };
        };

      in
      {
        packages = {
          default = jiratui;
          jiratui = jiratui;
        };

        apps = {
          default = flake-utils.lib.mkApp {
            drv = jiratui;
            name = "jiratui";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            python3
            python3Packages.pip
            python3Packages.uv
          ];
        };
      }
    ) //
    {
      # Home Manager module
      homeManagerModules.jiratui = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.programs.jiratui;

          # Convert attribute set to YAML format
          settingsFormat = pkgs.formats.yaml { };
          configFile = settingsFormat.generate "jiratui.yaml" cfg.settings;

        in {
          options.programs.jiratui = {
            enable = mkEnableOption "JiraTUI";

            package = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.jiratui;
              defaultText = literalExpression "jiratui";
              description = "The JiraTUI package to install.";
            };

            settings = mkOption {
              type = settingsFormat.type;
              default = { };
              example = literalExpression ''
                {
                  jira_api_base_url = "https://your-company.atlassian.net";
                  jira_base_url = "https://your-company.atlassian.net";
                  search_results_per_page = 65;
                  search_issues_default_day_interval = 15;
                  show_issue_web_links = true;
                  default_project_key_or_id = "MY-PROJECT";
                  ignore_users_without_email = true;
                  pre_defined_jql_expressions = {
                    "1" = {
                      label = "Work in the current sprint";
                      expression = "sprint in openSprints()";
                    };
                  };
                  jql_expression_id_for_work_items_search = 1;
                }
              '';
              description = ''
                Configuration written to {file}`$XDG_CONFIG_HOME/jiratui/jiratui.yaml`.

                See the example configuration at
                <https://github.com/whyisdifficult/jiratui/blob/main/jiratui.example.yaml>
                for available options.

                Note: Sensitive information like API tokens should be set via environment
                variables (JIRA_TUI_JIRA_API_TOKEN, JIRA_TUI_JIRA_API_USERNAME) or a
                separate .env file, not in this configuration.
              '';
            };

            environmentFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              example = "/run/secrets/jiratui-env";
              description = ''
                Path to a file containing environment variables for JiraTUI.
                This file should contain sensitive information like:

                ```
                JIRA_TUI_JIRA_API_USERNAME=your-username
                JIRA_TUI_JIRA_API_TOKEN=your-token
                ```

                The file will be sourced before running JiraTUI commands.
              '';
            };
          };

          config = mkIf cfg.enable {
            home.packages = [ cfg.package ];

            xdg.configFile."jiratui/jiratui.yaml" = mkIf (cfg.settings != { }) {
              source = configFile;
            };

            # Create a wrapper script that sources the environment file if provided
            home.file.".local/bin/jiratui-wrapped" = mkIf (cfg.environmentFile != null) {
              text = ''
                #!/bin/sh
                if [ -f "${cfg.environmentFile}" ]; then
                  set -a
                  . "${cfg.environmentFile}"
                  set +a
                fi
                exec ${cfg.package}/bin/jiratui "$@"
              '';
              executable = true;
            };

            # Add the wrapper to PATH if environment file is specified
            home.sessionPath = mkIf (cfg.environmentFile != null) [
              "${config.home.homeDirectory}/.local/bin"
            ];
          };
        };

      # NixOS module (optional, for system-wide installation)
      nixosModules.jiratui = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.programs.jiratui;
        in {
          options.programs.jiratui = {
            enable = mkEnableOption "JiraTUI system-wide";

            package = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.jiratui;
              defaultText = literalExpression "jiratui";
              description = "The JiraTUI package to install system-wide.";
            };
          };

          config = mkIf cfg.enable {
            environment.systemPackages = [ cfg.package ];
          };
        };
    };
}
