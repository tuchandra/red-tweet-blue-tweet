"""Store the tweets contained in JSON files into a database. This assumes that
MongoDB is installed and listening on localhost, and that the tweets are all
stored in one directory (the path to which must be modified appropriately).

This script assumes several things:
 - MongoDB is listening on localhost/27017 (can be configured in __main__)
 - database of tweets is called "twitter", collection called "tweets", and
   a smaller testing connection is "tweets_small" (can be configured at
   the top of store_tweets() and in __main__)
 - JSON files are stored in ../../../raid/RT82540 (can be configured in
   store_tweets())
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


def copy_sample(client, col1, col2, number = 10000):
    """Copy a sample of tweets from one collection to another.

    client: pymongo.MongoClient to connect to
    col1: source collection
    col2: target collection
    number: number of tweets to transfer
    """

    pipeline = [{ "$sample" : {"size" : number}}]
    col2.insert_many(col1.aggregate(pipeline))

    return


def drop_duplicates(client, collection):
    """Drop duplicate tweets (based on "id") from a collection."""

    # Reference: https://stackoverflow.com/a/33151782
    pipeline = [{ "$group" : { "_id" : { "tweet_id" : "$id" },
                               "uniqueIDs" : { "$addToSet" : "$_id" },
                               "count" : { "$sum" : 1 }}
                },
                { "$match" : { "count" : { "$gt" : 1 }}
                }]

    cursor = collection.aggregate(pipeline, allowDiskUse = True)

    # Cursor is a generator that has elements 
    # {"uniqueIDs" : [xx, xx, xx], "count" : yy, "_id" : {"tweet_id": zz}}
    # the uniqueIDs are what identifies the record in the collection, but
    # the tweet_id is what the tweet's ID actually is.
    # 
    # We only want one record for each tweet_id.

    results = []
    for doc in cursor:
        tweet_ids = doc["uniqueIDs"]

        # Gather all duplicate tweets except the first
        for tweet_id in tweet_ids[1:]:
            results.append(pymongo.DeleteOne({ "_id" : tweet_id }))

    # Remove them all
    write_result = collection.bulk_write(results)


def count_distinct(client, collection):
    """Count the number of distinct tweets (by "id") in a collection."""

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

    tweets = client["twitter"]["tweets"]
    tweets_small = client["twitter"]["tweets_small"]

    # store_tweets(client)
    # copy_sample(client, tweets, tweets_small, 10000)
    # count_distinct(client, tweets)
    # drop_duplicates(client, tweets)
