"""Extract retweets from all of the filtered tweets.

"""

import csv
import os
import time

import pymongo

def export_retweets(client, collection_name):

    col = client["twitter"][collection_name]

    retweets = {}

    for i, tweet in enumerate(col.find({"retweeted_status": {"$exists" : True}}, no_cursor_timeout = True)):
        if i % 50000 == 0:
            print("Processed {} tweets".format(i))

        # Extract date and IDs of original user / retweeting user
        try:
            timestamp = time.strptime(tweet["created_at"], "%a %b %d %H:%M:%S +0000 %Y")
            tweet_date = time.strftime("%Y_%m_%d", timestamp)

            retweeter = tweet["user"]["id_str"]
            retweeted = tweet["retweeted_status"]["user"]["id_str"]

            tweet_info = (tweet_date, retweeter, retweeted)
        except:
            continue

        # Let retweets be a dictionary that has keys date (YY_MM_DD), and
        # values lists of retweet triples (date, retweeter, retweeted)
        try:
            retweets[tweet_date].append(tweet_info)
        except KeyError:
            retweets[tweet_date] = [tweet_info]

    # Write all of the retweet lists to files.
    for date, tweets in retweets.items():
        fname = "retweet_lists/retweets_{0}.csv".format(date)
        with open(fname, "w") as f:
            writer = csv.writer(f)
            for tweet in tweets:
                try:
                    writer.writerow(tweet)
                except:
                    continue


if __name__ == "__main__":
    client = pymongo.MongoClient("localhost", 27017)

    # Create output directory if it doesn't exist
    try:
        os.mkdir("retweet_lists")
    except OSError:
        pass

    export_retweets(client, "tweets_filtered")
