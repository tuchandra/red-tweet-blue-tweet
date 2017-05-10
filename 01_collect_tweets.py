"""Use Twitter Streaming API to collect tweets about a particular subject.
Run the stream for an hour, and store the tweets to a JSON file."""

import sys
import time

from tweepy.streaming import StreamListener
from tweepy import OAuthHandler
from tweepy import Stream

from auth import authorize


class FileOutputListener(StreamListener):
    """Listener that stores tweets to JSON file as they arrive.

    time_limit: amount of time (seconds) to keep the stream open
    output_file: JSON file to save tweets to
    """

    def __init__(self, time_limit, output_file):
        self.start_time = time.time()
        self.time_limit = time_limit
        self.output_file = output_file


    def on_data(self, tweet):
        """On each tweet, print it out while the stream is still active."""

        if (time.time() - self.start_time) < self.time_limit:
            self.output_file.write(str(tweet))
            return True

        else:
            return False

    def on_error(self, status):
        """Print error messages when they appear."""
        print(status)


if __name__ == "__main__":
    # Filter tweets with keywords
    keywords = ["trump", "comey", "FBI", "russia", "putin"]

    while True:
        # Setup output file
        t = time.strftime("tweets_%m%d_%H%M%S", time.localtime())

        # Have stream open for as long as possible
        try:
            with open("{0}.json".format(t), "a") as output_file:
                # Create and authorize listener
                time_limit = 60*60*4 - 1  # time in minutes
                listener = FileOutputListener(time_limit, output_file)
                auth = authorize()
                stream = Stream(auth, listener)

                twitterator = stream.filter(track = keywords)

        # Allow usual keys to still kill the script
        except KeyboardInterrupt:
            sys.exit()

        # On other exceptions, attempt to restart stream
        # Probably should act based on error code, but hopefully you don't
        # get in trouble with Twitter
        except Exception as e:
            pass
