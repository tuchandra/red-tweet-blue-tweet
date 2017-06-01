"""Remove duplicate tweets, records that aren't tweets, and apply filters.

We define "not tweets" as records which lack the "id" or "user" key.

We keep users for whom all of the following holds:
 - at least 25 followers
 - at least 100 statuses
 - at least 100 followed users
 - tweet in english

This script assumes:
 - MongoDB is listening on localhost/27017
 - The database is called "twitter" with collections "tweets" (original)
   and "tweets_filtered" (for after filtering)
"""

import pymongo


def transfer_tweets(client, source, dest):
    """Transfer tweets from source to dest collections. Apply above filters."""

    i = 0
    for document in source.find(no_cursor_timeout = True):
        # Keep track of processed documents
        i += 1
        if i % 1000 == 0:
            print("Processed {} documents".format(i))

        # If doc doesn't have "id" field or "user" field, not a tweet; skip
        if "id" not in document.keys() or "user" not in document.keys():
            continue

        # Check user constraints (described at top of file)
        if (document["user"]["followers_count"] < 25 or
            document["user"]["statuses_count"] < 100 or
            document["user"]["friends_count"] < 100 or
            document["user"]["lang"] != "en"):
            continue

        # Attempt to insert into target, unless we violate uniqueness
        try:
            dest.insert_one(document)
        except pymongo.errors.DuplicateKeyError:
            continue


if __name__ == "__main__":
    client = pymongo.MongoClient("localhost", 27017)
    tweets = client["twitter"]["tweets_small"]

    # Create tweets_filtered (and index) if it doesn't exist
    if "tweets_filtered" not in client["twitter"].collection_names():
        client["twitter"].create_collection("tweets")
        tweets_filtered.create_index("id", unique = True)

    tweets_filtered = client["twitter"]["tweets_filtered"]
    
    transfer_tweets(client, tweets, tweets_filtered)