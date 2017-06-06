"""Store the tweets contained in JSON files into a database.

The file does nothing when executed by default, to prevent unintentional
operations on the database. Use this as a utilities file, modify the __main__
block, and run when necessary.

This script assumes:
 - JSON files are stored in ../../../raid/RT82540 (change in store_tweets())
 - MongoDB is listening on localhost/27017
 - The database of interest is called "twitter"
"""

import json
import os
import sys

import pymongo


def store_tweets(client):
    """Read all JSON files and store all tweets to the database.

    client: pymongo.MongoClient to connect to
    """

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
                try:
                    collection.insert_one(json.loads(tweet))
                except KeyboardInterrupt:
                    sys.exit()
                except Exception as e:
                    print(e)
                    pass

        print("Wrote tweets from {} into database.".format(tweet_file))


def copy_sample(client, source_name, dest_name, number = 10000):
    """Copy a sample of tweets from one collection to another.

    client: pymongo.MongoClient to connect to
    source_name: source collection name
    dest_name: target collection name
    number: number of tweets to transfer
    """

    col1 = client["twitter"][source_name]
    col2 = client["twitter"][dest_name]

    pipeline = [{ "$sample" : {"size" : number}}]
    col2.insert_many(col1.aggregate(pipeline))

    return


def count_distinct(client, col_name):
    """Count the number of distinct tweets (by "id") in a collection.

    client: pymongo.MongoClient to connect to
    col_name: name of collection of interest
    """

    collection = client["twitter"][col_name]

    # Reference: https://gist.github.com/eranation/3241616
    pipeline = [{ "$group" : { "_id" : "$id"}},
                { "$group" : { "_id" : 1, 
                               "count" : { "$sum" : 1}}}
               ]

    for doc in collection.aggregate(pipeline, allowDiskUse = True):
        print(doc)

    print(collection.count())


if __name__ == "__main__":
    # Connect to database
    client = pymongo.MongoClient("localhost", 27017)

    # store_tweets(client)
    # copy_sample(client, "tweets_filtered", "tweets_small", 10000)
    # count_distinct(client, "tweets_filtered")
