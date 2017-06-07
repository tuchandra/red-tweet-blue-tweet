#===============================================================
# Do a thing, probably
#
# - files stored
# - estimates
#===============================================================

library(reshape2)
library(ggplot2)

#===============================================================
# Write a function
# 
# 
#===============================================================

expand_data <- function(results, bin_size = 0.25, min = -4, max = -4) { # are min/max needed?
    # Axes will be ideologies
    retweeter <- results$ideology_retweeter
    retweeted <- results$ideology_retweeted

    # Round ideologies to the nearest multiple of bin_size
    retweeter <- round(retweeter / bin_size, 0) * bin_size
    retweeted <- round(retweeted / bin_size, 0) * bin_size

    # Construct table (does pairwise counts), then collapse into single column
    t <- table(retweeter, retweeted)
    t <- melt(t)

    # Add proportions to table
    t$prop <- t$value / sum(t$value)

    return(t)
}


#===============================================================
# Make heatmaps on the daily
# 
# 
#===============================================================

load("estimates.Rdata")
estimates <- estimates[, c("id", "ideology")]

files <- list.files("retweet_lists/", full.names = TRUE)

pol1 <- list()
pol2 <- list()
pol3 <- list()


for (i in 1 : length(files) - 1) {  # the last file doesn't have enough data
    retweets <- read.csv(files[i], header = FALSE, 
                         col.names = c("date", "retweeter", "rewtweeted"))

    # Columns of retweets are "date" "retweeter" "retweeted", in that order
    # We need to merge with the ideology estimates. 

    # Set ID to retweeter, then join with the estimates, then reset names
    # Note that the column positions change on the join. Unclear why.
    names(retweets)[2] <- "id"
    retweets <- merge(retweets, estimates, by = "id")
    names(retweets)[1] <- "retweeter"
    names(retweets)[4] <- "ideology_retweeter"

    # Next, set ID to retweeted, then join with the estimates, then reset names
    names(retweets)[3] <- "id"
    retweets <- merge(retweets, estimates, by = "id")
    names(retweets)[1] <- "retweeted"
    names(retweets)[5] <- "ideology_retweeted"

    #
    # Compute assorted polarization indices.
    #

    # 1. Do the retweeter and original Twitter user share the same ideology?
    # Both indices are centered at 0.5, so shift them and multiply, then check
    # if the product is positive. Bools are 0 / 1, so mean gives the proportion.
    pol1 <- mean((retweets$ideology_retweeter - 0.5) * (retweets$ideology_retweeter - 0.5) > 0)
    pol1

    # 2. How often were the two authors within 1 point of each other (1 SD)?
    pol2 <- mean(abs(retweets$ideology_retweeter - retweets$ideology_retweeted) < 1)

    # 3. Average polarization of information that is retweeted (from paper)?
    pol3 <- mean(abs(retweets$ideology_retweeted - 0.5))

    #
    # Graph things!
    #

    # Construct heatmap
    rt_table <- expand_data(retweets)
    plt <- ggplot(rt_table, aes(x=retweeted, y=retweeter)) + geom_tile(aes(fill=prop))

    # Save plot
    date <- as.character(retweets[1, 3])
    fname = paste("plots/heatmap_", date, ".png", sep="")
    ggsave(filename = fname, plot = plt)
}
