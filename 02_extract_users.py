"""Extract authors of all of the collected tweets. Apply activity filters,
only keeping users for whom all of the following holds:
 - at least 25 followers
 - at least 100 statuses
 - at least 100 followed users
 - tweet in english
"""

import csv
import json

import tweepy

from auth import authorize

if __name__ == "__main__":
    # Each JSON file is a collection of tweets.
    files = ["0501_042904.json", "0501_042924.json"]

    # From each tweet collection, get users of interest
    for fname in files:
        user_set = set()

        with open(fname) as f:
            # Each line is a tweet or empty. Attempt to decode it as JSON,
            # and create set (no duplicates) of UserIDs who tweeted and meet
            # other activity conditions.
            for line in f:
                try:
                    l = json.loads(line)
                    user = l["user"]

                    # Since we have access to the user here, exclude those
                    # with fewer than 25 followers, 100 statuses, 100
                    # followed users, or those who don't tweet in english.
                    if (user["followers_count"] < 25 or 
                        user["statuses_count"] < 100 or 
                        user["friends_count"] < 100 or
                        user["lang"] != "en"):
                        continue

                    user_set.add(user["id_str"])

                except:
                    continue

            # tweet collection was named tweets_mmdd_hhmmss.json
            # make csv file users_mmdd_hhmmss.csv
            csv_name = "users_" + fname[7:].split(".")[0] + ".csv"
            with open(csv_name, "w") as csv_file:
                cw = csv.writer(csv_file)
                for user  in user_set:
                    cw.writerow([user,])
