# JiraTUI Nix Flake

This flake provides [JiraTUI](https://github.com/whyisdifficult/jiratui), a TUI for interacting with Atlassian Jira from your terminal, along with Home Manager integration for configuration management.

## Quick Start

### Using the flake directly

```bash
# Run JiraTUI directly from the flake
nix run github:your-username/jiratui-flake

# Or use the local flake
nix run .
```

### Installation

#### With Home Manager

Add to your `flake.nix` inputs:

```nix
{
  inputs = {
    jiratui.url = "github:your-username/jiratui-flake";
    # ... other inputs
  };
}
```

Then in your Home Manager configuration:

```nix
{ inputs, ... }:
{
  imports = [ inputs.jiratui.homeManagerModules.jiratui ];
  
  programs.jiratui = {
    enable = true;
    
    settings = {
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
        "2" = {
          label = "My assigned issues";
          expression = "assignee = currentUser() AND resolution = Unresolved";
        };
      };
      
      jql_expression_id_for_work_items_search = 1;
    };
    
    # Optional: Path to environment file containing sensitive credentials
    environmentFile = "/run/secrets/jiratui-env";
  };
}
```

#### System-wide with NixOS

Add to your NixOS configuration:

```nix
{ inputs, ... }:
{
  imports = [ inputs.jiratui.nixosModules.jiratui ];
  
  programs.jiratui.enable = true;
}
```

## Configuration

### Environment Variables

JiraTUI requires authentication credentials that should **not** be stored in the Nix store. Set these as environment variables or in a separate environment file:

```bash
# Required
export JIRA_TUI_JIRA_API_USERNAME="your-username"
export JIRA_TUI_JIRA_API_TOKEN="your-api-token"

# Optional (can be set in config file instead)
export JIRA_TUI_JIRA_API_BASE_URL="https://your-company.atlassian.net"
```

### Environment File (Recommended)

Create a file (e.g., `/run/secrets/jiratui-env`) with your credentials:

```
JIRA_TUI_JIRA_API_USERNAME=your-username
JIRA_TUI_JIRA_API_TOKEN=your-api-token
```

Then reference it in your Home Manager configuration:

```nix
programs.jiratui = {
  enable = true;
  environmentFile = "/run/secrets/jiratui-env";
  # ... other settings
};
```

### Getting Your Jira API Token

1. Go to your Atlassian account settings: https://id.atlassian.com/manage/api-tokens
2. Click "Create API token"
3. Give it a label and click "Create"
4. Copy the token and use it as `JIRA_TUI_JIRA_API_TOKEN`

## Usage

After installation and configuration:

```bash
# Launch the TUI interface
jiratui ui

# Search for issues in a project
jiratui issues search --project-key MY-PROJECT

# Search for a specific issue
jiratui issues search --key MY-PROJECT-123

# See all available commands
jiratui --help
```

## Configuration Options

The `settings` attribute in the Home Manager module accepts all configuration options from the [example config file](https://github.com/whyisdifficult/jiratui/blob/main/jiratui.example.yaml):

- `jira_api_base_url`: Base URL of your Jira instance API
- `jira_base_url`: Base URL of your Jira instance (for web links)
- `jira_user_group_id`: Your user group ID
- `jira_account_id`: Your account ID
- `search_results_per_page`: Number of results per page (default: 65)
- `search_issues_default_day_interval`: Default day interval for searches
- `show_issue_web_links`: Whether to show web links (default: true)
- `default_project_key_or_id`: Default project key to use
- `ignore_users_without_email`: Ignore users without email addresses
- `custom_field_id_sprint`: Custom field ID for sprint information
- `pre_defined_jql_expressions`: Predefined JQL expressions for quick searches
- `jql_expression_id_for_work_items_search`: Default JQL expression ID to use

## Development

To work on this flake:

```bash
# Enter development shell
nix develop

# Build the package
nix build

# Test the package
nix run
```

## Security Note

⚠️ **Never put sensitive credentials (API tokens, passwords) in your Nix configuration!** 

Always use:
- Environment variables
- External environment files
- Secret management systems (like agenix, sops-nix, etc.)

## License

This flake is provided under the same license as JiraTUI (MIT). See the [original repository](https://github.com/whyisdifficult/jiratui) for details.
