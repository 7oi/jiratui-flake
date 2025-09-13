# Example Home Manager configuration for JiraTUI
# Add this to your home.nix or similar configuration file

{ inputs, config, lib, pkgs, ... }:

{
  # Import the JiraTUI Home Manager module
  imports = [ inputs.jiratui.homeManagerModules.jiratui ];

  programs.jiratui = {
    enable = true;

    # Configuration settings (non-sensitive)
    settings = {
      # Jira instance URLs
      jira_api_base_url = "https://your-company.atlassian.net";
      jira_base_url = "https://your-company.atlassian.net";

      # Display settings
      search_results_per_page = 65;
      search_issues_default_day_interval = 15;
      show_issue_web_links = true;
      ignore_users_without_email = true;

      # Default project
      default_project_key_or_id = "SCRUM";

      # Optional: Custom field for sprint information
      # custom_field_id_sprint = "customfield_12345";

      # Optional: User/group IDs
      # jira_user_group_id = "12345";
      # jira_account_id = "098765";

      # Predefined JQL expressions for quick searches
      pre_defined_jql_expressions = {
        "1" = {
          label = "Work in the current sprint";
          expression = "sprint in openSprints()";
        };
        "2" = {
          label = "My assigned issues";
          expression = "assignee = currentUser() AND resolution = Unresolved";
        };
        "3" = {
          label = "Recently updated issues";
          expression = "updated >= -7d ORDER BY updated DESC";
        };
        "4" = {
          label = "Issues in review";
          expression = "status = 'In Review' OR status = 'Code Review'";
        };
      };

      # Default JQL expression to use (references the keys above)
      jql_expression_id_for_work_items_search = 1;
    };

    # Path to environment file containing sensitive credentials
    # This file should contain:
    # JIRA_TUI_JIRA_API_USERNAME=your-username
    # JIRA_TUI_JIRA_API_TOKEN=your-api-token
    environmentFile = "/run/secrets/jiratui-env";
  };
}

# Alternative: If you don't want to use an environment file,
# you can set environment variables in your shell configuration:
#
# home.sessionVariables = {
#   JIRA_TUI_JIRA_API_USERNAME = "your-username";
#   # Don't put the API token here! Use a secret management solution
# };
