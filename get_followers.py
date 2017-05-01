import time

import tweepy

from auth import authorize

if __name__ == "__main__":
    # Create and authorize API
    auth = authorize()
    api = tweepy.API(auth)

    # Get follower IDs of all members of Congress, per CSPAN's list
    for m in tweepy.Cursor(api.list_members, "cspan", "members-of-congress").items():
        print (m.screen_name, m.followers_count)
        print (m.followers_ids())

        break
