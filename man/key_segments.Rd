% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/key-segment.R
\name{key_segments}
\alias{key_segments}
\alias{key_segment_manual}
\alias{key_segment_map}
\alias{key_dendro}
\title{Segment keys}
\usage{
key_segment_manual(value, oppo, value_end = value, oppo_end = oppo, ...)

key_segment_map(data, ..., .call = caller_env())

key_dendro(dendro = NULL, type = "rectangle")
}
\arguments{
\item{value, value_end}{A vector that is interpreted to be along the scale
that the guide codifies.}

\item{oppo, oppo_end}{A vector that is interpreted to be orthogonal to the
\code{value} and \code{value_end} variables.}

\item{...}{\code{\link[rlang:topic-data-mask]{<data-masking>}} A set of mappings
similar to those provided to \code{\link[ggplot2:aes]{aes()}}, which will be
evaluated in the \code{data} argument.
For \code{key_segments_map()}, these \emph{must} contain \code{value} and \code{oppo} mappings.}

\item{data}{A \verb{<data.frame>} or similar object coerced by
\code{\link[ggplot2:fortify]{fortify()}} to a \verb{<data.frame>}, in which the \code{mapping}
argument is evaluated.}

\item{.call}{A \link[rlang:topic-error-call]{call} to display in messages.}

\item{dendro}{A data structure that can be coerced to a dendrogram through
the \code{\link[stats:dendrogram]{as.dendrogram()}} function. When \code{NULL}
(default) an attempt is made to search for such data in the scale.}

\item{type}{A string, either \code{"rectangle"} or \code{"triangle"}, indicating the
shape of edges between nodes of the dendrogram.}
}
\value{
For \code{key_segments_manual()} and \code{key_segments_map()}, a \verb{<data.frame>} with
the \verb{<key_range>} class.
}
\description{
These functions are helper functions for working with segment data as keys
in guides. They all share the goal of creating a guide key, but have
different methods:
\itemize{
\item \code{key_segment_manual()} directly uses user-provided vectors to set segments.
\item \code{key_segment_map()} makes mappings from a \verb{<data.frame>} to set segments.
\item \code{key_dendro()} is a specialty case for coercing dendrogram data to segments.
Be aware that setting the key alone cannot affect the scale limits, and
will give misleading results when used incorrectly!
}
}
\examples{
# Giving vectors directly
key_segment_manual(
  value = 0:1, value_end = 2:3,
  oppo  = 1:0, oppo_end  = 3:2
)

# Taking columns of a data frame
data <- data.frame(x = 0:1, y = 1:0, xend = 2:3, yend = 3:2)
key_segment_map(data, value = x, oppo = y, value_end = xend, oppo_end = yend)

# Using dendrogram data
clust <- hclust(dist(USArrests), "ave")
key_dendro(clust)(scale_x_discrete())
}
\seealso{
Other keys: 
\code{\link{key_group}},
\code{\link{key_range}},
\code{\link{key_specialty}},
\code{\link{key_standard}}
}
\concept{keys}
