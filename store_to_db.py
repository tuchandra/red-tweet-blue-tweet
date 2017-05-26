import json
import os

import pymongo


if __name__ == "__main__":
    # Connect to mongoDB
    client = pymongo.MongoClient("localhost", 27017)

    # Create collection of tweets
    if "tweets" not in client["twitter"].collection_names():
        client["twitter"].create_collection("tweets")

    collection = client["twitter"]["tweets"]

    # Read stored tweets and store into database.
    tweet_dir = "../../../raid/RT82540/"
    #tweet_dir = "tweets"  # this is a testing directory
    for tweet_file in sorted(os.listdir(tweet_dir)):
        fpath = os.path.join(tweet_dir, tweet_file)

        with open(fpath) as f:
            for tweet in f:
                collection.insert_one(json.loads(tweet))

        print("Wrote tweets from {} into database.".format(tweet_file))