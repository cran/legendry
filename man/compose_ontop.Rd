% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/compose-ontop.R
\name{compose_ontop}
\alias{compose_ontop}
\title{Compose guides on top of one another}
\usage{
compose_ontop(
  ...,
  args = list(),
  key = NULL,
  title = waiver(),
  angle = waiver(),
  theme = NULL,
  order = 0,
  position = waiver(),
  available_aes = NULL
)
}
\arguments{
\item{...}{Guides to stack in \link[=guide-composition]{composition}. Each guide
can be specified as one of the following:
\itemize{
\item A \verb{<Guide>} class object.
\item A \verb{<function>} that returns a \verb{<Guide>} class object.
\item A \verb{<character[1]>} naming such a function, without the \code{guide_} or
\code{primitive_} prefix.
}}

\item{args}{A \verb{<list>} of arguments to pass to guides that are given either
as a function or as a string.}

\item{key}{A \link[=key_standard]{standard key} specification. The key is shared
among all guides that have \code{NULL} keys themselves. See more information
in the linked topic.}

\item{title}{A \verb{<character[1]>} or \verb{<expression[1]>} indicating the title of
the guide. If \code{NULL}, the title is not shown. The default,
\code{\link[ggplot2:waiver]{waiver()}}, takes the name of the scale object or
the name specified in \code{\link[ggplot2:labs]{labs()}} as the title.}

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

\item{theme}{A \code{\link[ggplot2:theme]{<theme>}} object to style the guide individually or
differently from the plot's theme settings. The \code{theme} argument in the
guide overrides and is combined with the plot's theme.}

\item{order}{A positive \verb{<integer[1]>} that specifies the order of this guide among
multiple guides. This controls in which order guides are merged if there
are multiple guides for the same position. If \code{0} (default), the order is
determined by a hashing indicative settings of a guide.}

\item{position}{A \verb{<character[1]>} giving the location of the guide. Can be one of \code{"top"},
\code{"bottom"}, \code{"left"} or \code{"right"}.}

\item{available_aes}{A \verb{<character>} giving aesthetics that must match the
the guides.}
}
\value{
A \verb{<ComposeOntop>} composite guide object.
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#experimental}{\figure{lifecycle-experimental.svg}{options: alt='[Experimental]'}}}{\strong{[Experimental]}}

This guide can place place other guides on top of one another.
}
\examples{
# Using the ontop composition to get two types of ticks with different
# lengths
ggplot(mpg, aes(displ, hwy)) +
  geom_point() +
  guides(x = compose_ontop(
    guide_axis_base(
      key_manual(c(2, 4, 6)),
      theme = theme(
        axis.ticks = element_line(colour = "limegreen"),
        axis.ticks.length = unit(11, "pt")
      )
    ),
    guide_axis_base(
      key_manual(c(3, 5, 7)),
      theme = theme(
        axis.ticks = element_line(colour = "tomato"),
        axis.ticks.length = unit(5.5, "pt")
      )
    )
  ))
}
\seealso{
Other composition: 
\code{\link{compose_crux}()},
\code{\link{compose_sandwich}()},
\code{\link{compose_stack}()},
\code{\link{guide-composition}}
}
\concept{composition}
