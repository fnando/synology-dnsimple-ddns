# Synology and DDNS using DNSimple

## Heroku setup

You can deploy the app by click the button below. Don't forget to add the
following env vars:

1. `API_KEY`: to generate an API key, use
   `dd if=/dev/urandom bs=32 count=1 2>/dev/null | openssl base64 -A`.
2. `DNSIMPLE_API_KEY`: to create a new API key, visit https://dnsimple.com/user.

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/fnando/synology-dnsimple-ddns)

## Synology setup

1. Go to Control Panel > External Access > DDNS.
2. Click "Customize Provider"
3. Under service provider, type a readable name like "HerokuDDNS".
4. Under "Query URL", paste the url
   `https://<your app name>.herokuapp.com/update?ip=__MYIP__&api_key=__PASSWORD__&host=__HOSTNAME__`.
5. Click "Save".
6. Click "Add". This will start the "Add DDNS" wizard.
7. Select the DDNS provider you added on step 3.
8. Type the hostname you want to set on DDNS.
9. Add "x" as your Username/Email.
10. Paste the API key from your Sinatra app as the password.
11. Click "OK".
