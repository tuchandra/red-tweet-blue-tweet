"""Store the tweets contained in JSON files into a database. This assumes that
MongoDB is installed and listening on localhost, and that the tweets are all
stored in one directory (the path to which must be modified appropriately).
"""

import json
import os
import sys

import pymongo

def store_tweets(client):
    """Read all JSON files and store all tweets to the database.

    client: pymongo.MongoClient to connect to"""

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


def copy_sample(client, num = 10000):
    """Copy a sample of tweets to another collection."""

    tweets = client["twitter"]["tweets"]
    new_collection = client["twitter"]["tweets_small"]

    pipeline = [{ "$sample" : {"size" : num}}]
    new_collection.insert_many(tweets.aggregate(pipeline))

    return


def drop_duplicates(client):
    """Drop duplicate tweet IDs from the database.

    Assumption: using database name "twitter" and collection name "tweets".

    client: pymongo.MongoClient to connect to"""

    tweets = client["twitter"]["tweets_small"]

    # Reference: https://stackoverflow.com/a/34738547
    # Group tweets by ID, and put into groups with like IDs. Then keep the
    # tweet-groups that have >= 2 elements (i.e., duplicates)
    pipeline = [ {"$group" : {"_id": "$id", 
                              "count": {"$sum": 1}, 
                              "ids": {"$push": "$id"}}},
                 {"$match" : {"count": {"gte": 2}}}
               ]

    requests = []
    for document in tweets.aggregate(pipeline, allowDiskUse = True):
        it = iter(document["ids"])
        next(it)
        for id in it:
            requests.append(pymongo.DeleteOne({"_id": id}))

    pipeline = [{ "$group" : { "_id" : { "tweet_id" : "$id" },
                               "uniqueIDs" : { "$addToSet" : "$_id" },
                               "count" : { "$sum" : 1 }}
                },
                { "$match" : { "count" : { "$gt" : 1 }}
                }]

    cursor = tweets.aggregate(pipeline, allowDiskUse = True)

    #while (next(cur)):

    requests = []
    for document in tweets.aggregate(pipeline, allowDiskUse = True):
        it = iter(document)
        next(it)

        i = 1
        while i < len(document["uniqueIDs"]):
            requests.append(pymongo.DeleteOne({"id" : document["uniqueIDs"][i]}))
            i += 1

    print(r)

    # r = tweets.bulk_write(requests)

def count_distinct(client):
    """Count the number of distinct tweets (by tweet ID) in collection."""

    tweets = client["twitter"]["tweets_small"]

    # Reference: https://gist.github.com/eranation/3241616
    pipeline = [{ "$group" : { "_id" : "$id"}},
                { "$group" : { "_id" : 1, 
                               "count" : { "$sum" : 1}}}
               ]


    for doc in tweets.aggregate(pipeline, allowDiskUse = True):
        print(doc)


if __name__ == "__main__":
    # Connect to database
    client = pymongo.MongoClient("localhost", 27017)

    # store_tweets(client)
    # drop_duplicates(client)
    count_distinct(client)
    # copy_sample(client, 10000)
