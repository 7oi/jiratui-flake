# Example NixOS configuration for JiraTUI
# Add this to your configuration.nix or a separate module

{ inputs, config, lib, pkgs, ... }:

{
  # Import the JiraTUI NixOS module
  imports = [ inputs.jiratui.nixosModules.jiratui ];

  # Enable JiraTUI system-wide
  programs.jiratui = {
    enable = true;
    # Optionally specify a specific package version
    # package = inputs.jiratui.packages.${pkgs.system}.jiratui;
  };

  # Optional: Create a system-wide environment file template
  environment.etc."jiratui/jiratui.env.example" = {
    text = ''
      # JiraTUI Environment Configuration
      # Copy this file to a secure location and update with your credentials

      # Required: Your Jira username (usually your email)
      JIRA_TUI_JIRA_API_USERNAME=your-username@company.com

      # Required: Your Jira API token
      # Get this from: https://id.atlassian.com/manage/api-tokens
      JIRA_TUI_JIRA_API_TOKEN=your-api-token-here

      # Optional: Jira base URL (can also be set in config file)
      JIRA_TUI_JIRA_API_BASE_URL=https://your-company.atlassian.net
    '';
  };
}
