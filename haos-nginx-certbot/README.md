# Nginx Certbot HAOS Add-on

This add-on wraps [`jonasal/nginx-certbot`](https://github.com/JonasAlfredsson/docker-nginx-certbot) for Home Assistant OS.

It uses the existing Bumper data folder:

```text
/share/bumper
```

Expected files:

```text
/share/bumper/configs/nginx.conf
/share/bumper/configs/user_conf.d/app.conf
/share/bumper/configs/nginx-certbot.env
/share/bumper/configs/letsencrypt/
```

Set `certbot_email` in the add-on options or keep `CERTBOT_EMAIL` in:

```text
/share/bumper/configs/nginx-certbot.env
```
