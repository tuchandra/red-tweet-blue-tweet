#===============================================================
# Do a thing, probably
#
# - files stored
# - estimates
#===============================================================

library(reshape2)
library(ggplot2)


#===============================================================
# FORMAT_DATA: creates pairwise counts matrix of ideology pairs
# for original author and retweeter, then coerce them into a
# shape that is conducive to plotting later, and transform to
# proportions.
#===============================================================

format_data <- function(results, bin_size = 0.25) {
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
# CREATE HEATMAPS
# For each day of data, create a heatmap of the ideology pairs
# described above. To do this, we combine the retweets extracted
# ages ago with the estimates. The combined file is saved to
# an Rdata to save future time.
#===============================================================

load("estimates.Rdata")
estimates <- estimates[, c("id", "ideology")]

files <- list.files("retweet_lists/", full.names = TRUE)

# Last file doesn't have enough data
for (i in 1 : (length(files) - 1)) {
    retweets <- read.csv(files[i], header = FALSE, 
                         col.names = c("date", "retweeter", "rewtweeted"))

    # Columns of retweets are "date" "retweeter" "retweeted", in that order.
    # We need to merge with the ideology estimates.

    # Set ID to retweeter, then join with the estimates, then reset names
    # Note that the column positions change on the join. It is unclear why.
    names(retweets)[2] <- "id"
    retweets <- merge(retweets, estimates, by = "id")
    names(retweets)[1] <- "retweeter"
    names(retweets)[4] <- "ideology_retweeter"

    # Next, set ID to retweeted, then join with the estimates, then reset names
    names(retweets)[3] <- "id"
    retweets <- merge(retweets, estimates, by = "id")
    names(retweets)[1] <- "retweeted"
    names(retweets)[5] <- "ideology_retweeted"

    # Save retweets + estimates dataframe for later (it is costly to compute)
    date <- as.character(retweets[1, 3])
    fname <- paste("retweet_lists/rt_est_", date, ".Rdata", sep = "")
    save(retweets, file = fname)

    # Construct heatmap -- a great deal of this plot function is credited to
    # the original authors, and the rest to StackOverflow and ggplot2 docs.
    rt_table <- format_data(retweets)

    # Format date as, e.g., "May 12," for the title of the plot
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
