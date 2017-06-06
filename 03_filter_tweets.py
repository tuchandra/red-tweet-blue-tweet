"""Remove duplicate tweets, records that aren't tweets, and apply spam filters.

We define "not tweets" as records which lack the "id" or "user" key.

We then keep tweets that have users for whom all of the following holds:
 - at least 25 followers
 - at least 100 statuses
 - at least 100 followed users
 - tweet in English

This script assumes:
 - MongoDB is listening on localhost/27017
 - The database is called "twitter" with collection "tweets" (original), and
   that collection "tweets_filtered" is the target (created if doesn't exist)
"""

import pymongo


def transfer_tweets(client, source, dest):
    """Transfer tweets from source to dest collections. Apply above filters.

    Note: deletes tweets from source collection (after successful insertion)!

    client: pymongo.MongoClient to connect to
    source: source collection name
    dest: target collection name
    """

    i = 0
    for document in source.find(no_cursor_timeout = True):
        # Keep track of processed documents
        i += 1
        if i % 50000 == 0:
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
            source.delete-one(document)
        except pymongo.errors.DuplicateKeyError:
            continue


if __name__ == "__main__":
    client = pymongo.MongoClient("localhost", 27017)

    # Create tweets_filtered (and index) if it doesn't exist
    if "tweets_filtered" not in client["twitter"].collection_names():
        client["twitter"].create_collection("tweets")
        tweets_filtered.create_index("id", unique = True)

    tweets_filtered = client["twitter"]["tweets_filtered"]
    tweets = client["twitter"]["tweets"]
    
    transfer_tweets(client, tweets, tweets_filtered)
