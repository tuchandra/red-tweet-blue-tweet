#===============================================================
# Estimate ideologies by projecting the users (rows) onto the
# ideological subspace created from the previous script.
# Normalize the ideological values to facilitate analysis.
#
# This script assumes:
#  - adjacency matrix stored in adj_matrix.Rdata
#  - correspondence analysis result stored in correspondence.Rdata
#
#===============================================================

library(Matrix)
load("adj_matrix.Rdata")  # matrix y
load("correspondence.Rdata")  # matrix res

#===============================================================
# COLUMN PROJECTIONS
# This is mostly unnecessary, because we did not do a second
# stage census to gather additional political accounts. Due
# to this, there are no additional columns to project onto the
# original subspace.
#
# We keep this section to remain consistent with the original
# authors' work.
#===============================================================

col.df <- data.frame(
    colname = res$colnames,
    coord1 = res$colcoord[,1],
    coord2 = res$colcoord[,2],
    coord3 = res$colcoord[,3],
    stringsAsFactors = FALSE)

save(col.df, file = "col_coord.Rdata")


#===============================================================
# ROW PROJECTIONS
# This part is actually necessary. Because we identified the
# ideological subspace as those users who follow at least 5
# political accounts, we now need to account for those who
# follow fewer than 5 (but still at least 1). 
#
# To do this, we project all of the rows into the subspace
# created by the correspondence analysis. Some rows already
# exist in the subspace (those users who follow 5 or more
# politicians), but the projection for them is simply the
# identity.
#===============================================================

load("adj_matrix.Rdata")  # reloads entire y
load("col_coord.Rdata")

# We can only project users who follow at least one of our politicians.
y <- y[rowSums(y)>0,]  # (472,985 x 443)

# Load column coordinates, but remove labels (443 x 3)
colcoords <- matrix(as.matrix(col.df[,2:4]), ncol=3)
gam.00 <- colcoords  # (443 x 3)

# Compute column masses
colmasses <- colSums(y) / sum(y)
cs <- colmasses  # length 443

# Matrix of singular values (472985, 3)
# [[sigma1, sigma2, sigma3],
#  [sigma1, sigma2, sigma3],
#             ...          ]
svphi <- matrix(res$sv[1:3], nrow = nrow(y), ncol = 3, byrow = TRUE)

points <- as.matrix(y) * 1  # (472985 x 443), and the *1 coerces to numeric
rs.sum <- rowSums(points)  # length 472985

# Normalize points so that rows sum to 1, then transpose (so columns sum to 1)
base2 <- points / matrix(rs.sum, nrow = nrow(points), ncol = ncol(points))
base2 <- t(base2)

# Prepare to project
cs.0 <- matrix(cs, nrow = nrow(base2), ncol = ncol(base2))  # (443 x 472985)
base2 <- base2 - cs.0  # (443 x 472985)

# Do the projection
# t(as.matrix(base2)) has dim (472985 x 443); gam.00 has dim (443 x 3)
# multiplying gives (472985 x 3); then divide by singular values svphi
phi <- t(as.matrix(base2)) %*% gam.00 / svphi
row.df <- phi

# Save projection matrix
row.df <- data.frame(
    rowname = rownames(y)[1:nrow(row.df)],
    coord1 = row.df[,1],
    coord2 = row.df[,2],
    coord3 = row.df[,3],
    sum = rowSums(y),
    stringsAsFactors = FALSE)

save(row.df, file = "row_coord.Rdata")


#===============================================================
# NORMALIZATION
# Combine estimates of ideology for both rows (users) and
# columns (politicians). This takes advantage of the structure
# of the analysis, allowing us to use the same correspondence
# analysis for two groups of people.
# 
# Normalize both sets of estimates; users should be normally
# distributed on N(0, 1), while politicians should have sd = 1.
#
# Combine them, then save the output.
#===============================================================

# First, normalize the row estimates
load("row_coord.Rdata")  # reload row.df

# First singular value represents ideology
users <- row.df
names(users)[c(1, 2)] <- c("id", "ideology")

# Keep relevant values
users <- users[, c("id", "ideology", "sum")]
users$type <- "users"
users$party <- ""

# Rescale to N(0, 1). Sort the users by their ideology first, then generate
# values from N(0, 1), sort those, and assign them in turn to each user.
users2 <- users[order(users$ideology + rnorm(length(users$ideology), 0, 0.05)),]

p <- rnorm(nrow(users), 0, 1)
p <- sort(p)
users2$ideology <- p

users <- users[,c("id", "ideology", "type", "party", "sum")]

# Next, normalize column estimates
load("output/col_coord.Rdata")  # reload col.df

# Set up columns
col.df$id <- col.df$colname
col.df$ideology <- col.df$coord1
col.df$sum <- 0
col.df$party <- ""
col.df$type <- "politicians"

# Keep columns of interest
politicians <- col.df[,c("id", "ideology", "type", "party", "sum")]

# Rescale column ideologies to have standard deviation 1.
# (Note res$rowcoord[,1] used to have user ideologies, since those were the
# first singular values.)
ratio <- sd(politicians$ideology) / sd(res$rowcoord[,1])
politicians$ideology <- politicians$ideology / ratio

# Combine datasets
estimates <- rbind(politicians, users)
estimates <- estimates[!duplicated(estimates$id),]

save(estimates, file = "estimates.rdata")
