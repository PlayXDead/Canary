{
  description = "Flutter development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; # Specify NixOS 25.05
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true; # Required for Android SDK components
          android_sdk = {
            accept_license = true;
          };
        };
      };
    in {
      devShells.default = pkgs.mkShell {
        name = "flutter-dev-shell";

        packages = with pkgs; [
          flutter
          jdk # Required for Android development
          android-tools.adb # For ADB functionality
          android-tools.fastboot # For fastboot functionality
          # Add specific Android SDK packages if needed, e.g.,
          # androidenv.androidPkgs_9_0.androidsdk
          # You might need to specify specific build-tools versions
          # like android-sdk.build-tools-34-0-0
        ];

        # Environment variables for Android SDK
        shellHook = ''
          export ANDROID_HOME=${pkgs.android-sdk}/share/android-sdk
          export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
          export JAVA_HOME=${pkgs.jdk}
        '';
      };
    });
}
