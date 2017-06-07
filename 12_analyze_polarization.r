#===============================================================
# Do polarization analysis by day, using the combined retweets
# and estimates dataset. Collect and plot various metrics of
# polarization over time.
#
# Assumptions
#  - data stored in retweet_estimates/rt_est_[date].Rdata
#  - output folder plots/ exists
#===============================================================

library(ggplot2)
files <- list.files("retweet_estimates/", full.names = TRUE)
dates <- list.files("retweet_estimates/")

for (i in 1 : length(dates)) {
    dates[i] <- substr(dates[i], 8, 17)
    # dates[i,] <- strptime(dates[i,], "%Y_%m_%d")
}

#===============================================================
# COMPUTE POLARIZATION INDEX
# For each day, compute different measures of political
# polarization. 
#===============================================================

pol1.days <- c()
pol2.days <- c()
pol3.days <- c()

for (i in 1 : length(files)) {
    load(files[i])  # loads dataframe called retweets

    # 1. Do the retweeter and original Twitter user share the same ideology?
    #    We can check if the product is positive; then they're the same.
    pol1 <- mean(retweets$ideology_retweeter * retweets$ideology_retweeted > 0)
    pol1.days <- rbind(pol1.days, pol1)

    # 2. How often were the two authors within 1 point of each other (1 SD)?
    pol2 <- mean(abs(retweets$ideology_retweeter - retweets$ideology_retweeted) < 1)
    pol2.days <- rbind(pol2.days, pol2)

    # 3. Average polarization of information that is retweeted (from paper)?
    pol3 <- mean(abs(retweets$ideology_retweeted))
    pol3.days <- rbind(pol3.days, pol3)

}

#===============================================================
# PLOT POLARIZATION INDEXES
# For each measure of polarization, plot it and save the result.
#===============================================================

# tba