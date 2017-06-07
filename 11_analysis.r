#===============================================================
# Do a thing, probably
#
# - files stored
# - estimates
#===============================================================

load("estimates.Rdata")
estimates <- estimates[, c("id", "ideology")]

files <- list.files("rewteet_lists/", full.names = TRUE)

for (i in 1 : length(files)) {
    retweets <- read.csv(files[i], header = FALSE, 
                         col.names = c("date", "retweeter", "rewtweeted"))

    # Columns of retweets are "date" "retweeter" "retweeted", in that order
    # We need to merge with the ideology estimates. 

    # Set ID to retweeter, then join with the estimates, then reset names
    # Note that the column positions change on the join. Unclear why.
    names(retweets)[2] <- "id"
    retweets <- merge(retweets, estimates, by = "id")
    names(retweets)[1] <- "retweeter"
    names(retweets)[4] <- "retweeter_ideology"

    # Next, set ID to retweeted, then join with the estimates, then reset names
    names(retweets)[3] <- "id"
    retweets <- merge(retweets, estimates, by = "id")
    names(retweets)[1] <- "retweeted"
    names(retweets)[5] <- "retweeted_ideology"

}