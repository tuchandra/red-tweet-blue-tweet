#===============================================================
# Validate ideology estimates of our model by comparing them to
# the political parties of members of Congress.
#
# We note that not every member of Congress was included in our
# model, because collecting the followers of some of them was
# infeasible.
#
# This should theoretically show a correlation between the
# members' political party and our ideological estimate. We draw
# paired boxplots to view this qualitatively.
#
# This script assumes:
#  - ideology estimates stored in estimates.Rdata
#  - republicans list stored in congress_republicans.csv
#  - democrats list stored in congress_democrats.csv
#===============================================================

library(ggplot2)

#===============================================================
# APPLY ESTIMATES
#===============================================================

load("estimates.Rdata")  # loads matrix estimates

# Load lists of congresspeople from saved files
reps <- read.csv("congress_republicans.csv", header = FALSE, 
                 col.names = c("id", "name", "followers", "party"))

dems <- read.csv("congress_democrats.csv", header = FALSE, 
                 col.names = c("id", "name", "followers", "party"))

reps <- data.frame(reps)
dems <- data.frame(dems)

politicians <- rbind(dems, reps)

# Apply estimates; keep non-null ideology estimates
p <- merge(x = politicians, y = estimates[c("id", "ideology")], by = "id")


#===============================================================
# CHECK ACCURACY
#===============================================================

# Check how well an ideology threshold of 0.5 works; that is,
# if we classify everyone below 0.5 as a Democrat, and
# everyone above it as a Republican, how well do we do?

t <- table(p$ideology > 0.5, p$party == "R")
(t[1,1] + t[2,2]) / sum(t)  # 0.991

# Apparently, 99% accuracy. Remember that we never used party
# affiliation when constructing the estimates; we only used
# the structure of the followers network.

# Next, perform a t-test to see if the estimates differ
# significantly for Democrats and Republicans in Congress.
t.test(p[p$party == "R",]$ideology, p[p$party == "D",]$ideology, var.equal = TRUE)

# t = 53.7
# There is clearly a difference in our estimates, which is reassuring.


#===============================================================
# PLOTS
#===============================================================

# Boxplot
plt <- ggplot(p, aes(x = party, y = ideology)) +
       geom_boxplot(fill="lightblue") +
       labs(title="Ideology Estimates of Members of Congress",
            x="Party Affiliation", y="Ideology Estimate") +
       coord_flip()

ggsave(f = "plots/congress_boxplot.png", plot = plt, height = 3, width = 8)

# Jitter plot
plt <- ggplot(p, aes(x = party, y = ideology)) +
       geom_jitter(aes(color=party)) +
       labs(title="Ideology Estimates of Members of Congress",
            x="Party Affiliation", y="Ideology Estimate") +
       theme(legend.position="none") +
       scale_color_manual(values=c("slateblue1", "firebrick1")) +
       coord_flip()

ggsave(f = "plots/congress_jitter.png", plot = plt, height = 3, width = 8)
