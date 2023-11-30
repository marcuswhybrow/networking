{
  description = "Dialogue to toggle WiFi or networking w/ desktop entry";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rofi.url = "github:marcuswhybrow/rofi";
  };

  outputs = inputs: let 
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    rofi = "${inputs.rofi.packages.x86_64-linux.rofi}/bin/rofi";
    nmcli = "${pkgs.networkmanager}/bin/nmcli";
    notifySend = "${pkgs.libnotify}/bin/notify-send";
    networking = pkgs.writeShellScript "networking" ''
      options=(
        "Wifi"
        "Ethernet"
        "Disable"
      )

      choice="$(\
        printf '%s\n' "''${options[@]}" | \
        ${rofi} -dmenu -i -theme-str 'entry { placeholder: "Networking"; }' \
      )"

      case $choice in
        Wifi)
          ${nmcli} networking on
          ${nmcli} radio wifi on
          notifyMsg="Switching to Wifi"
          ;;
        Ethernet)
          ${nmcli} networking on
          ${nmcli} radio wifi off
          notifyMsg="Switching to Ethernet"
          ;;
        Disable)
          ${nmcli} radio wifi off
          ${nmcli} networking off
          notifyMsg="Disabling Networking"
          ;;
        *) exit 1;;
      esac

      ${notifySend} \
        --app-name networking \
        --urgency normal \
        --expire-time 2000 \
        --hint string:x-dunst-stack-tag:networking \
        "$notifyMsg"
    '';
  in {
    packages.x86_64-linux.networking = pkgs.runCommand "networking" {} ''
      mkdir -p $out/bin
      ln -s ${networking} $out/bin/networking

      mkdir -p $out/share/applications
      tee $out/share/applications/networking.desktop << EOF
      [Desktop Entry]
      Version=1.0
      Name=Networking
      GenericName=Turn WiFi and Ethernet on or off
      Terminal=false
      Type=Application
      Exec=$out/bin/networking
      EOF
    '';

    packages.x86_64-linux.default = inputs.self.packages.x86_64-linux.networking;
  };
}
