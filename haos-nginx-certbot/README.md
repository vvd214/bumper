# Nginx Certbot HAOS Add-on

This add-on wraps [`jonasal/nginx-certbot`](https://github.com/JonasAlfredsson/docker-nginx-certbot) for Home Assistant OS.

It uses a configurable data folder. The default is:

```text
/share/bumper
```

You can change `data_path` in the add-on options, for example:

```text
/share/nginx_certbot
```

Expected files:

```text
<data_path>/configs/nginx.conf
<data_path>/configs/user_conf.d/app.conf
<data_path>/configs/nginx-certbot.env
<data_path>/configs/letsencrypt/
```

Set `certbot_email` in the add-on options or keep `CERTBOT_EMAIL` in:

```text
<data_path>/configs/nginx-certbot.env
```
