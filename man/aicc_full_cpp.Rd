% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RcppExports.R
\name{aicc_full_cpp}
\alias{aicc_full_cpp}
\title{AICc formula for several sets, alternative definition}
\usage{
aicc_full_cpp(h, X_list, mcov_list, S_scale_dist, y_list, negative)
}
\arguments{
\item{h}{Numeric. Specifies the scaling (sigma)}

\item{X_list}{List}

\item{mcov_list}{List}

\item{S_scale_dist}{Logical. Indicates whether Mahalanobis distance should be scaled with the
number of variables}

\item{y_list}{List.}

\item{negative}{Logical.}
}
\value{
Scalar with the numeric value of the AICc formula
}
\description{
AICc formula for several sets, alternative definition
}
\author{
Martin Jullum
}
\keyword{internal}
