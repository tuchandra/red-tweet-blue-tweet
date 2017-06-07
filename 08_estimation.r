#===============================================================
# DO A THING MAYBE
# UNCLEAR
#
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
# Project each column into the subspace; create matrix col.df
# with dimension (443, 3) giving three coordinates for each col
#===============================================================

# 
# # Principal coordinates for rows
# psi <- res$rowcoord  # 110824 x 3
# 
# # Normalize y, so that columns sum to 1
# y.sum <- apply(y, 2, sum)  # flattens to 443-element list
# ys <- y / matrix(y.sum, nrow=nrow(y), ncol=ncol(y), byrow=TRUE)
# 
# # Matrix of singular values (443, 3)
# # [[sigma1, sigma2, sigma3],
# #  [sigma1, sigma2, sigma3],
# #             ...          ]
# svgam <- matrix(res$sv[1:3], nrow=ncol(h), ncol=3, byrow=TRUE)
# 
# # Compute projection
# # t(hs) is hs.transpose
# # %*% is matrix multiplication
# # t(hs) %*% psi is (443 x 110824) * (110824 x 3) = (443 x 3)
# # Then divides elementwise by svgam, so g = (443 x 3)
# g <- (t(hs) %*% Psi) / svgam
# 

# All of the above might have been unnecessary, because we don't have any
# new columns from the second stage being projected onto first stage space.
col.df <- data.frame(
    colname = res$colnames,
    coord1 = res$colcoord[,1],
    coord2 = res$colcoord[,2],
    coord3 = res$colcoord[,3],
    stringsAsFactors = FALSE)

save(col.df, file = "col_coord.Rdata")


#===============================================================
# PROJECT ROWS
#
# UNCLEAR
#===============================================================

# Note: We cannot simply take res$rowcoord, because we didn't use all of
# the rows in computing the SVD (we used those who followed at least 5
# politicians).

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
