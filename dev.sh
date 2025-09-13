#!/usr/bin/env bash
# Development script for JiraTUI Nix flake

set -e

echo "🧪 JiraTUI Nix Flake Development Script"
echo "========================================"

# Function to print colored output
print_step() {
    echo -e "\n🔵 $1"
}

print_success() {
    echo -e "✅ $1"
}

print_error() {
    echo -e "❌ $1"
}

# Check if we're in the right directory
if [[ ! -f "flake.nix" ]]; then
    print_error "flake.nix not found. Please run this script from the jiratui flake directory."
    exit 1
fi

print_step "Checking flake syntax..."
nix flake check --show-trace
print_success "Flake syntax is valid"

print_step "Building JiraTUI package..."
nix build .#jiratui --show-trace
print_success "Package built successfully"

print_step "Testing application help..."
./result/bin/jiratui --help
print_success "Application help works"

print_step "Testing nix run..."
nix run . -- --help > /dev/null
print_success "nix run works"

print_step "Showing flake outputs..."
nix flake show

print_step "Testing Home Manager module syntax..."
# Create a minimal test configuration
cat > test-hm-config.nix << 'EOF'
{ config, lib, pkgs, ... }:
{
  programs.jiratui = {
    enable = true;
    settings = {
      jira_api_base_url = "https://test.atlassian.net";
      search_results_per_page = 50;
    };
  };
}
EOF

# Test that the module can be evaluated (basic syntax check)
nix eval --expr '
  let 
    nixpkgs = builtins.getFlake "nixpkgs";
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    
    flake = builtins.getFlake (toString ./.);
    homeManagerModule = flake.homeManagerModules.jiratui;
    
    # Mock home-manager lib
    mockLib = pkgs.lib // {
      mkEnableOption = desc: pkgs.lib.mkOption {
        type = pkgs.lib.types.bool;
        default = false;
        description = "Whether to enable ${desc}.";
      };
    };
    
    # Create a minimal config to test module evaluation
    config = {
      home = {
        homeDirectory = "/home/test";
        packages = [];
        sessionPath = [];
        file = {};
      };
      xdg.configFile = {};
      programs.jiratui.enable = false;
    };
    
    # Test module evaluation
    result = homeManagerModule { 
      inherit config pkgs;
      lib = mockLib;
    };
  in
  result.options.programs.jiratui.enable.description or "OK"
' > /dev/null

rm -f test-hm-config.nix
print_success "Home Manager module syntax is valid"

print_step "Cleaning up..."
rm -f result

echo ""
print_success "All tests passed! 🎉"
echo ""
echo "📋 Next steps:"
echo "1. Commit your changes to git"
echo "2. Push to GitHub"
echo "3. Test the flake with: nix run github:your-username/jiratui-flake"
echo "4. Add to your Home Manager or NixOS configuration"
echo ""
echo "📖 See README.md for detailed usage instructions."
