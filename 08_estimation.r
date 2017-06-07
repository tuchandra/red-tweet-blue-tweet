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

save(col.df, file="col_coord.Rdata")
