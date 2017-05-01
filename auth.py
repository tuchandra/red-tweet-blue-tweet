"""Authentication function for Twitter API.

Requires credentials.json in format listed below, storing keys and secrets."""

import json
import os

from tweepy import OAuthHandler


def authorize():
    """Read credentials from file and return OAuthHandler ready to be used."""

    secret_file = os.path.expanduser('credentials.json')
    
    if not os.path.exists(secret_file):
        raise Exception("Credentials file not found.")

    with open(secret_file) as f:
        secret_contents = json.loads(f.read())

    # Unpack contents. Format of file:
    # { "consumer_key" : "...",
    #   "consumer_secret" : "...",
    #   "access_token" : "...",
    #   "access_secret" : "..."
    # }

    consumer_key = secret_contents["consumer_key"]
    consumer_secret = secret_contents["consumer_secret"]
    access_token = secret_contents["access_token"]
    access_secret = secret_contents["access_secret"]

    # OAuthHandler is a tweepy thing; with it, one can use other API functions
    auth = OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_secret)

    return auth
