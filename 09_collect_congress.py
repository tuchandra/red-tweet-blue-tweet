"""Collect Twitter IDs and party affiliations of congresspeople.

We obtain the list of all Democrats and Republicans in Congress (both House
and Senate). This will later be used to validate our model.
"""

import csv
import itertools

import tweepy

from auth import authorize


def write_users(users, party):
    """Given list of users, write relevant information to CSV file.

    For Republicans, info written to congress_republicans.csv.
    For Democrats, info written to congress_democrats.csv.

    users: iterator of users
    party: string, "R" (republican) or "D" (democrat)
    """

    accounts = []

    # Get party, user ID, username, and number of followers (the useful info)
    for user in users:
        party = party
        user_id = user.id_str
        username = user.name
        followers = user.followers_count

        user_info = (user_id, username, followers, party)
        accounts.append(user_info)

    # Write to appropriate file
    if party == "R":
        fname = "congress_republicans.csv"
    elif party == "D":
        fname = "congress_democrats.csv"

    with open(fname, "w") as outfile:
        writer = csv.writer(outfile)
        for acct_info in accounts:
            try:
                writer.writerow(acct_info)
            except:
                continue

        print("Wrote list to {}".format(fname))


def get_congresspeople(auth):
    """Get lists of congresspeople and writes information to CSV file."""

    # Authorize API
    api = tweepy.API(auth, wait_on_rate_limit = True, wait_on_rate_limit_notify = True)

    # List of all Republicans in Congress from @SenateRepublicans and 
    # @HouseRepublicans
    house_reps = tweepy.Cursor(api.list_members, "HouseGOP", "house-republicans").items()
    senate_reps = tweepy.Cursor(api.list_members, "senategop", "senaterepublicans").items()

    republicans = itertools.chain(house_reps, senate_reps)
    write_users(republicans, "R")

    # List of all Democrats in Congress from @TheDemocrats
    house_dems = tweepy.Cursor(api.list_members, "TheDemocrats", "house-democrats").items()
    senate_dems = tweepy.Cursor(api.list_members, "TheDemocrats", "senate-democrats").items()

    democrats = itertools.chain(house_dems, senate_dems)
    write_users(democrats, "D")


if __name__ == "__main__":
    auth = authorize()
    get_congresspeople(auth)
