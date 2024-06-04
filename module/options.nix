{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) attrsOf anything package;

  json = pkgs.formats.json {};

  cfg = config.services.diskPartitioning;
  diskSchema = cfg.schema;
in {
  options.services.diskPartitioning = {
    enable = mkEnableOption "diskix";

    schema = mkOption {
      type = attrsOf anything; # TODO: add schema validation
      default = {};
      description = "Disk partitioning schema.";
    };

    schemaJson = mkOption {
      type = json.type;
      default = builtins.toJSON diskSchema;
      internal = true;
      readOnly = true;
    };

    partitionScript = mkOption {
      type = package;
      internal = true;
      readOnly = true;
      default = pkgs.writeShellScript "partitionDisks.sh" ''
        schema=${cfg.schemaJson}

        # parse the JSON schema
        disks=$(echo "$schema" | jq -r 'keys[]')

        for disk in $disks; do
          device=$(echo "$schema" | jq -r ".$disk.device")
          tableType=$(echo "$schema" | jq -r ".$disk.tableType")

          # create partition table
          parted --script "$device" mklabel "$tableType"

          # get partitions
          partitions=$(echo "$schema" | jq -r ".$disk.partitions[] | @base64")

          for partition in $partitions; do
            _jq() {
              echo "$partition" | base64 --decode | jq -r "$1"
            }

            name=$(_jq '.name')
            type=$(_jq '.type')
            start=$(_jq '.start')
            end=$(_jq '.end')
            filesystem=$(_jq '.filesystem')

            # create partition
            parted --script "$device" mkpart "$type" "$start" "$end"

            # format partition
            partitionNumber=$(parted --script "$device" print | grep -A1 '^Number' | tail -n1 | awk '{print $1}')
            mkfs."$filesystem" "$device""$partitionNumber"
          done
        done
      '';
    };

    mountScript = mkOption {
      type = package;
      internal = true;
      readOnly = true;
      default = pkgs.writeShellScript "partitionDisks.sh" ''
        schema=${cfg.schemJson}

        # parse the JSON schema
        disks=$(echo "$schema" | jq -r 'keys[]')

        for disk in $disks; do
          device=$(echo "$schema" | jq -r ".$disk.device")

          # get partitions
          partitions=$(echo "$schema" | jq -r ".$disk.partitions[] | @base64")

          for partition in $partitions; do
            _jq() {
              echo "$partition" | base64 --decode | jq -r "$1"
            }

            name=$(_jq '.name')
            number=$(_jq '.number')
            filesystem=$(_jq '.filesystem')
            mountPoint=$(_jq '.mountPoint')

            # create mount point if it doesn't exist
            mkdir -p "$mountPoint"

            # mount partition
            mount -t "$filesystem" "$device""$number" "$mountPoint"
          done
        done
      '';
    };
  };
}
