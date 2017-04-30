import json
import os

from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream

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

class StdOutListener(StreamListener):
    """Listener that prints tweets as they arrive."""

    def on_data(self, data):
        print(data)
        return True

    def on_error(self, status):
        print(status)



if __name__ == "__main__":
    consumer_key, consumer_secret, access_token, access_secret = read_credentials()

    listener = StdOutListener()
    auth = OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_token, access_secret)

    stream = Stream(auth, listener)

    keywords = ["trump", "#trump"]
    twitterator = stream.filter(track = keywords)
