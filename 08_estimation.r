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

# Matrix of singular values (472985, 3)
# [[sigma1, sigma2, sigma3],
#  [sigma1, sigma2, sigma3],
#             ...          ]
svphi <- matrix(res$sv[1:3], nrow = nrow(y), ncol = 3, byrow = TRUE)

cs <- colmasses  # length 443
gam.00 <- colcoords  # (443 x 3)

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
