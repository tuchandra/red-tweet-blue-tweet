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
    # Setup output file
    t = time.strftime("tweets_%m%d_%H%M%S", time.localtime())
    with open("{0}.json".format(t), "a") as output_file:
        # Create and authorize listener
        listener = FileOutputListener(3540, output_file)
        auth = authorize()
        stream = Stream(auth, listener)

        # Filter tweets with keywords
        keywords = ["1mayis", "mayday"]
        twitterator = stream.filter(track = keywords)
