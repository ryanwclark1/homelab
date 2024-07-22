


To retrieve your Global API key:
Log in to the Cloudflare dashboard and go to User Profile > API Tokens.
In the API Keys section, click View button of Global API Key.

Note: when used in docker-compose.yml all dollar signs in the hash need to be doubled for escaping.
To create user:password pair, it's possible to use this command:
echo $(htpasswd -nB user) | sed -e s/\\$/\\$\\$/g