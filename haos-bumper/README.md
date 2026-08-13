# Bumper HAOS Add-on

This add-on runs Bumper on Home Assistant OS.

## Data

Copy the personal Bumper data folder to this HAOS share path:

```text
/share/bumper
```

The folder should contain the existing `data/` and `certs/` directories, for example:

```text
/share/bumper/data/bumper.db
/share/bumper/data/passwd
/share/bumper/certs/ca.crt
/share/bumper/certs/bumper.crt
/share/bumper/certs/bumper.key
```

## Configuration

`announce_ip` may be left empty. The add-on will try to detect the primary HAOS host IPv4 address through the Supervisor API.

`mqtt_admin_users` is a comma-separated list of MQTT users that bypass robot/client state handling. The default example value is:

```text
admin
```
