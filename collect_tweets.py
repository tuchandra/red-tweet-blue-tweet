import json
import os

from twitter import OAuth, TwitterStream
from twitter.util import printNicely

def read_credentials():
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

    return consumer_key, consumer_secret, access_token, access_secret

if __name__ == "__main__":
    consumer_key, consumer_secret, access_token, access_secret = read_credentials()
    stream = TwitterStream(auth=OAuth(access_token, access_secret,
                                      consumer_key, consumer_secret))

    keywords = ["climate", "#climatemarch", "global warming"]
    twitterator = stream.statuses.filter(track = ["#climatemarch"])


    for tweet in twitterator:
        print(tweet)
