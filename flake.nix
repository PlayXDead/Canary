{
  description = "Flutter environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # Use nixos-unstable for newer packages
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          android_sdk.accept_license = true;
        };

        androidEnv = pkgs.androidenv.override { licenseAccepted = true; };

        androidComposition = androidEnv.composeAndroidPackages {
          cmdLineToolsVersion = "latest"; # Use 'latest' for command line tools
          platformToolsVersion = "latest"; # Use 'latest' for platform tools
          buildToolsVersions = [ "34.0.0" ]; # Keep only recent build tools if not needing older
          platformVersions = [ "34" "35" ]; # Add newer Android platforms
          abiVersions = [ "x86_64" ];
          includeNDK = true; # Include NDK if needed for native development
          includeSystemImages = true;
          systemImageTypes = [ "google_apis" "google_apis_playstore" ];
          includeEmulator = true;
          useGoogleAPIs = true;
          extraLicenses = [
            "android-googletv-license"
            "android-sdk-arm-dbt-license"
            "android-sdk-license"
            "android-sdk-preview-license"
            "google-gdk-license"
            "intel-android-extra-license"
            "intel-android-sysimage-license"
            "mips-android-sysimage-license"
          ];
        };

        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell = with pkgs; mkShell rec {
          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          JAVA_HOME = jdk17.home; # Update to a more recent JDK like jdk17
          FLUTTER_ROOT = flutter;
          DART_ROOT = "${flutter}/bin/cache/dart-sdk";
          # GRADLE_OPTS might not be necessary with newer Android SDKs, remove if not experiencing issues
          # QT_QPA_PLATFORM can be adjusted based on emulator's Qt version and Wayland support
          
          buildInputs = [
            androidSdk
            flutter
            qemu_kvm
            gradle
            jdk17 # Use jdk17
            vulkan-loader # Ensure these are present for emulator hardware acceleration
            libGL
          ];

          # Ensure LD_LIBRARY_PATH is set correctly for emulator
          LD_LIBRARY_PATH = "${lib.makeLibraryPath [ vulkan-loader libGL ]}";

          shellHook = ''
            # Ensure PUB_CACHE is set and added to PATH
            export PUB_CACHE="$HOME/.pub-cache"
            export PATH="$PATH:$PUB_CACHE/bin"
          '';
        };
      }
    );
}
