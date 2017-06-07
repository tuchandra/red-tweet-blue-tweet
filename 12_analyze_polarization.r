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


df1 <- data.frame(pol1 = pol1.days, day = c(1:19))
plt <- ggplot(df1, aes(x=day, y=pol1)) + geom_point() + geom_smooth() +
       labs(x="Date", y="Proportion of Pairs", 
            title="Proportion of pairs with same-direction ideology") +
       scale_x_continuous(labels = c("May 10", "May 20", "May 29"), breaks = c(1, 10, 19))
ggsave(filename = "plots/polarize1.png", plot = plt, width=6, height=4)


df2 <- data.frame(pol2 = pol2.days, day = c(1:19))
plt <- ggplot(df2, aes(x=day, y=pol2)) + geom_point() + geom_smooth() +
       labs(x="Date", y="Proportion of Pairs", 
            title="Proportion of pairs within 1 standard deviation of each other") +
       scale_x_continuous(labels = c("May 10", "May 20", "May 29"), breaks = c(1, 10, 19))
ggsave(filename = "plots/polarize2.png", plot = plt, width=6, height=4)


df3 <- data.frame(pol3 = pol3.days, day = c(1:19))
plt <- ggplot(df3, aes(x=day, y=pol3)) + geom_point() + geom_smooth() +
       labs(x="Date", y="Polarization Measure", 
            title="Average polarization of retweeted information") +
       scale_x_continuous(labels = c("May 10", "May 20", "May 29"), breaks = c(1, 10, 19)) +
       scale_y_continuous(breaks = seq(1.0, 1.3, by=0.05))
ggsave(filename = "plots/polarize3.png", plot = plt, width=6, height=4)
