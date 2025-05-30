% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/primitive-fence.R
\name{primitive_fence}
\alias{primitive_fence}
\title{Guide primitive: fence}
\usage{
primitive_fence(
  key = "range_auto",
  rail = "none",
  angle = waiver(),
  oob = "squish",
  drop_zero = TRUE,
  pad_discrete = 0.5,
  levels_text = NULL,
  levels_post = NULL,
  levels_rail = NULL,
  theme = NULL,
  position = waiver()
)
}
\arguments{
\item{key}{A \link[=key_range]{range key} specification. See more information
in the linked topic.}

\item{rail}{A \verb{<character[1]>} giving an option for how to display fence
railing. Can be either \code{"none"} (default) to display no railings, \code{"inner"}
to draw one rail closer to the plot panel, \code{"outer"} to display one rail
farther from the plot panel, or \code{"both"} to sandwich the labels between
rails.}

\item{angle}{A specification for the text angle. Compared to setting the \code{angle} argument
in \code{\link[ggplot2:element]{element_text()}}, this argument uses some
heuristics to automatically pick the \code{hjust} and \code{vjust} that you
probably want. Can be one of the following:
\itemize{
\item \code{NULL} to take angles and justification settings directly from the theme.
\item \code{\link[ggplot2:waiver]{waiver()}} to allow reasonable defaults in special
cases.
\item A \verb{<numeric[1]>} between -360 and 360 for the text angle in degrees.
}}

\item{oob}{A method for dealing with out-of-bounds (oob) ranges. Can be one
of \code{"squish"}, \code{"censor"} or \code{"none"}.}

\item{drop_zero}{A \verb{<logical[1]>} whether to drop near-zero width ranges
(\code{TRUE}, default) or preserve them (\code{FALSE}).}

\item{pad_discrete}{A \verb{<numeric[1]>} giving the amount ranges should be
extended when given as a discrete variable. This is applied after
the \code{drop_zero} setting.}

\item{levels_text}{A list of \verb{<element_text>} objects to customise how
text appears at every level.}

\item{levels_post, levels_rail}{A list of \verb{<element_line>} objects to
customise how fence posts and rails are displayed at every level.}

\item{theme}{A \code{\link[ggplot2:theme]{<theme>}} object to style the guide individually or
differently from the plot's theme settings. The \code{theme} argument in the
guide overrides and is combined with the plot's theme.}

\item{position}{A \verb{<character[1]>} giving the location of the guide. Can be one of \code{"top"},
\code{"bottom"}, \code{"left"} or \code{"right"}.}
}
\value{
A \verb{<PrimitiveFence>} primitive guie that can be used inside other
guides.
}
\description{
This function constructs a fence \link[=guide-primitives]{guide primitive}. The
customisation options are easier to understand if we view fence 'post' as the
vertical pieces of a real world fence, and the 'rail' as the horizontal
pieces.
}
\section{Styling options}{
Below are the \link[ggplot2:theme]{theme} options that determine the styling of
this guide, which may differ depending on whether the guide is used in an
axis or legend context.

Common to both types is the following:
\itemize{
\item \code{legendry.fence.post} an \code{\link[ggplot2:element]{<element_line>}} for the
line used to draw the pieces orthogonal to the direction of the scale.
\item \code{legendry.fence.rail} an \code{\link[ggplot2:element]{<element_line>}} for the
line used to draw the pieces parallel to the direction of the scale.
}
\subsection{As an axis guide}{
\itemize{
\item \verb{axis.text.\{x/y\}.\{position\}} an \code{\link[ggplot2:element]{<element_text>}}
for the text displayed.
}
}

\subsection{As a legend guide}{
\itemize{
\item \code{legend.text} an \code{\link[ggplot2:element]{<element_text>}} for the text
displayed.
}
}
}

\examples{
# A standard plot
p <- ggplot(mpg, aes(interaction(drv, year), displ)) +
  geom_point()

key <- key_range_manual(c(2, 4), c(5, 6), c("A", "B"))

# Adding as secondary guides
p + guides(
  x.sec = primitive_fence(rail = "inner"),
  y.sec = primitive_fence(key = key, rail = "outer")
)
}
\seealso{
Other primitives: 
\code{\link{primitive_box}()},
\code{\link{primitive_bracket}()},
\code{\link{primitive_labels}()},
\code{\link{primitive_line}()},
\code{\link{primitive_segments}()},
\code{\link{primitive_spacer}()},
\code{\link{primitive_ticks}()},
\code{\link{primitive_title}()}
}
\concept{primitives}
