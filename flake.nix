{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
  };

  description = "Pushbullet utilities";

  outputs = { self, nixpkgs }:

    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      accessTokenPath = "/tmp/pushbullet-token";
      url = "https://api.pushbullet.com/v2";
      checkForAccessToken = ''
        if [[ ! -e ${accessTokenPath} ]]
        then
          echo >&2 "Please write your Pushbullet access token to ${accessTokenPath}"
          exit 1
        fi
      '';
      preamble =
        ''
          ${checkForAccessToken}
          curl --silent \
               --header 'Access-Token: '$(<${accessTokenPath}) \
               --header 'Content-Type: application/json' '';
      pushPreamble =
        ''
          ${preamble} \
            --request POST \
            --data-binary @- \
            ${url}/pushes'';
    in
    {
      defaultPackage.x86_64-linux = self.packages.x86_64-linux.pbpush;
      packages.x86_64-linux.pbpush =
        pkgs.writeShellScriptBin "pbpush" ''
          ${pushPreamble} <<EOF
          ${builtins.toJSON {
            title = "$1";
            body = "$2";
            type = "note";
          }}
          EOF
        '';

      packages.x86_64-linux.pbpushto =
        pkgs.writeShellScriptBin "pbpushto" ''
          ${pushPreamble} <<EOF
          ${builtins.toJSON {
            iden = "$1";
            title = "$2";
            body = "$3";
            type = "note";
          }}
          EOF
        '';

      packages.x86_64-linux.pbpushchannel =
        pkgs.writeShellScriptBin "pbpushchannel" ''
          ${pushPreamble} <<EOF
          ${builtins.toJSON {
            channel_tag = "$1";
            title = "$2";
            body = "$3";
            type = "note";
          }}
          EOF
        '';

      packages.x86_64-linux.pbdevices =
        pkgs.writeShellScriptBin "pbpush" ''
          ${preamble} ${url}/devices | \
            ${pkgs.jq}/bin/jq -r ".devices | .[] | (.iden + \" \" + if .nickname? then .nickname else \"<unknown>\" end)"
        '';
    };
}
