import time

from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream

from auth import authorize


class StdOutListener(StreamListener):
    """Listener that prints tweets as they arrive.

    time_limit: amount of time (seconds) to keep the stream open
    """

    def __init__(self, time_limit):
        self.start_time = time.time()
        self.time_limit = time_limit

    def on_data(self, data):
        """On each tweet, print it out while the stream is still active."""

        if (time.time() - self.start_time) < self.time_limit:
            print(data)
            return True

        else:
            return False

    def on_error(self, status):
        """Print error messages when they appear."""
        print(status)


if __name__ == "__main__":
    # Create and authorize listener
    listener = StdOutListener(10)
    auth = authorize()
    stream = Stream(auth, listener)

    # Filter tweets keywords
    keywords = ["trump"]
    twitterator = stream.filter(track = keywords)
