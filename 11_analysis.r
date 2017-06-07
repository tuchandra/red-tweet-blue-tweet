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


for (i in 1 : (length(files) - 1)) {  # the last file doesn't have enough data
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

    # 2. How often were the two authors within 1 point of each other (1 SD)?
    pol2 <- mean(abs(retweets$ideology_retweeter - retweets$ideology_retweeted) < 1)

    # 3. Average polarization of information that is retweeted (from paper)?
    pol3 <- mean(abs(retweets$ideology_retweeted - 0.5))

    #
    # Graph things!
    #

    # Construct heatmap -- a great deal of this plot function is credited to
    # the original authors, and the rest to StackOverflow and ggplot2 docs
    rt_table <- expand_data(retweets)
    date <- as.character(retweets[1, 3])
    date_name <- strftime(strptime(date, "%Y_%m_%d"), "%B %d")
    plt_title <- paste("Retweet Polarization on", date_name)

    plt <- ggplot(rt_table, aes(x=retweeted, y=retweeter)) +
           geom_raster(aes(fill=prop), color="white") +
           scale_y_continuous(limits=c(-3,3), expand=c(0,0)) +
           scale_x_continuous(limits=c(-3,3), expand=c(0,0)) +
           scale_fill_gradient(low="white", high="black", name="Proportion\nof tweets",
                               limits=c(0, 0.05), breaks=seq(0, 0.05, by=0.01)) +
           theme(panel.background = element_rect(fill="white"),
                 panel.border = element_rect(fill=NA)) +
           labs(x="Ideology Estimate for Original Author",
                y="Ideology Estimate for Retweeter",
                title=plt_title)

    # Save plot
    fname = paste("plots/heatmap_", date, ".png", sep="")
    ggsave(filename = fname, plot = plt, width=4, height=4)
}
