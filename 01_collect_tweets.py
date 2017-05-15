"""Use Twitter Streaming API to collect tweets about a particular subject.
Run the stream for an hour, and store the tweets to a JSON file.

This script is designed to be run once every hour. Because of this, the
stream disconnects after an hour, and the script will end after an hour."""

import pathlib  
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
    keywords = ["trump", "comey", "FBI", "justice", "department"]
    
    start_time = time.time()
    total_runtime = 60*60 - 60*1 

    path = os.path.abspath("../../../raid/RT82540")

    while True:
        try:
            # Setup output file
            t = time.strftime(path + "/tweets_%m%d_%H%M%S", time.localtime())
            with open("{0}.json".format(t), "a") as output_file:
                # This script is designed to run for one hour. To achieve
                # this, have an initial 1 hour time limit, but subtract off
                # the time the script has already been running (in case an
                # old listener crashed, for instance).
                time_limit = total_runtime - (time.time() - start_time)

                if time_limit < 0:
                    sys.exit()

                # Create and authorize listener
                listener = FileOutputListener(time_limit, output_file)
                auth = authorize()
                stream = Stream(auth, listener)

                twitterator = stream.filter(track = keywords)

                # If the listener returns False, time is up; done streaming.
                if not twitterator:
                    break

        # Allow usual keys to still kill the script
        except KeyboardInterrupt:
            sys.exit()

        # On other exceptions, attempt to restart stream
        # Probably should act based on error code, but hopefully you don't
        # get in trouble with Twitter
        except Exception as e:
            print(e)
            pass
