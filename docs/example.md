```nix
services.diskPartitioning = {
    enable = true;
    schema = {
      disk1 = {
        device = "/dev/sda";
        tableType = "gpt"; # or "mbr"
        partitions = [
          {
            name = "boot";
            type = "primary"; # or "extended" for MBR
            start = "0%";
            end = "1GiB";
            filesystem = "ext4";
          }
          {
            name = "root";
            type = "primary";
            start = "1GiB";
            end = "100%";
            filesystem = "ext4";
          }
        ];
      };

      disk2 = {
        device = "/dev/sdb";
        tableType = "gpt";
        partitions = [
          {
            name = "data";
            type = "primary";
            start = "0%";
            end = "100%";
            filesystem = "xfs";
          }
        ];
      };
    };
  };
```

Will produce:

```json
{
  "disk1": {
    "device": "/dev/sda",
    "partitions": [
      {
        "end": "1GiB",
        "filesystem": "ext4",
        "name": "boot",
        "start": "0%",
        "type": "primary"
      },
      {
        "end": "100%",
        "filesystem": "ext4",
        "name": "root",
        "start": "1GiB",
        "type": "primary"
      }
    ],
    "tableType": "gpt"
  },
  "disk2": {
    "device": "/dev/sdb",
    "partitions": [
      {
        "end": "100%",
        "filesystem": "xfs",
        "name": "data",
        "start": "0%",
        "type": "primary"
      }
    ],
    "tableType": "gpt"
  }
}
```
