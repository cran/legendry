# Constructor -------------------------------------------------------------

#' Guide primitive: line
#'
#' This function constructs a ticks [guide primitive][guide-primitives].
#'
#' @param bidi A `<logical[1]>`: whether ticks should be drawn bidirectionally
#'   (`TRUE`) or in a single direction (`FALSE`, default).
#' @inheritParams primitive_labels
#'
#' @return A `PrimitiveTicks` primitive guide that can be used inside other
#'   guides.
#' @export
#' @family primitives
#'
#' @details
#' # Styling options
#'
#' Below are the [theme][ggplot2::theme] options that determine the styling of
#' this guide, which may differ depending on whether the guide is used in
#' an axis or in a legend context.
#'
#' Common to both types is the following:
#'
#' ## As an axis guide
#'
#' * `axis.ticks.{x/y}.{position}` an [`<element_line>`][ggplot2::element_line]
#'   for major tick lines.
#' * `axis.minor.ticks.{x/y}.{position}` an
#'   [`<element_line>`][ggplot2::element_line] for minor tick lines.
#' * `legendry.axis.mini.ticks` an [`<element_line>`][ggplot2::element_line]
#'   internally inheriting from the minor ticks for the smallest ticks in e.g.
#'   log axes.
#' * `axis.ticks.length.{x/y}.{position}` a [`<unit>`][grid::unit] for the major
#'   ticks length.
#' * `axis.minor.ticks.length.{x/y}.{position}` a [`<unit>`][grid::unit] for the
#'   minor ticks length.
#' * `legendry.axis.mini.ticks.length` a [`<unit>`][grid::unit] internally
#'   inheriting from the minor tick length for the smallest ticks in e.g.
#'   log axes.
#'
#' ## As a legend guide
#'
#' * `legend.ticks` an [`<element_line>`][ggplot2::element_line] for major tick
#'   lines.
#' * `legendry.legend.minor.ticks` an [`<element_line>`][ggplot2::element_line]
#'   for minor tick lines.
#' * `legendry.legend.mini.ticks` an [`<element_line>`][ggplot2::element_line]
#'   for the smallest ticks in e.g. log axes.
#' * `legend.ticks.length` a [`<unit>`][grid::unit] for the major ticks length.
#' * `legendry.legend.minor.ticks.length` a [`<unit>`][grid::unit] for the
#'   minor ticks length.
#' * `legendry.legend.mini.ticks.length` a [`<unit>`][grid::unit] for the
#'   smallest ticks in e.g. log axes.
#'
#' @examples
#' # A standard plot
#' p <- ggplot(mpg, aes(displ, hwy)) +
#'   geom_point()
#'
#' # Adding as secondary guides
#' p + guides(x.sec = primitive_ticks(), y.sec = primitive_ticks())
primitive_ticks <- function(key = NULL, bidi = FALSE, theme = NULL,
                            position = waiver()) {
  check_bool(bidi)
  new_guide(
    key = key,
    bidi = bidi,
    theme = theme,
    position = position,
    available_aes = c("any", "x", "y", "r", "theta"),
    super = PrimitiveTicks
  )
}

# Class -------------------------------------------------------------------

#' @export
#' @rdname legendry_extensions
#' @format NULL
#' @usage NULL
PrimitiveTicks <- ggproto(
  "PrimitiveTicks", Guide,

  params = new_params(key = NULL, bidi = FALSE),

  hashables = exprs(key$.value),

  elements = list(
    position = list(
      ticks = "axis.ticks",       ticks_length = "axis.ticks.length",
      minor = "axis.minor.ticks", minor_length = "axis.minor.ticks.length"
    ),
    legend = list(
      ticks        = "legend.ticks",
      ticks_length = "legend.ticks.length",
      minor        = "legendry.legend.minor.ticks",
      minor_length = "legendry.legend.minor.ticks.length",
      # Mini ticks for legends don't have complicated inheritance
      mini         = "legendry.legend.mini.ticks",
      mini_length  = "legendry.legend.mini.ticks.length"
    )
  ),

  extract_key = standard_extract_key,

  extract_params = primitive_extract_params,

  transform = function(self, params, coord, panel_params) {
    params$key <-
      transform_key(params$key, params$position, coord, panel_params)
    params
  },

  setup_params = primitive_setup_params,

  setup_elements = primitive_setup_elements,

  override_elements = function(params, elements, theme) {

    # Count how many ticks of each type we need
    type <- params$key$.type %||% "major"
    n_major <- sum(type == "major")
    n_minor <- sum(type == "minor")
    n_mini  <- sum(type == "mini")

    # We need to setup mini ticks for axes, as the inheritance tree isn't
    # mirrored for every aesthetic/position combination.
    if (n_mini > 0 && params$aesthetic %in% c("x", "y")) {
      elements$mini <- combine_elements(
        theme$legendry.axis.mini.ticks,
        elements$minor
      )
      elements$mini_length <- combine_elements(
        theme$legendry.axis.mini.ticks.length,
        elements$minor_length
      )
    }

    # Set absent ticks to empty
    elements <- zap_tick(elements, "ticks", n_major)
    elements <- zap_tick(elements, "minor", n_minor)
    elements <- zap_tick(elements, "mini",  n_mini)

    lengths <- c("ticks_length", "minor_length", "mini_length")
    elements$size <- inject(range(!!!elements[lengths], 0))
    elements
  },

  build_ticks = function(key, elements, params, position = params$position) {
    type <- key$.type %||% "major"
    offset <- elements$offset
    major <- draw_ticks(
      vec_slice(key, type == "major"),
      elements$ticks, params, position, elements$ticks_length, offset
    )
    minor <- draw_ticks(
      vec_slice(key, type == "minor"),
      elements$minor, params, position, elements$minor_length, offset
    )
    mini <- draw_ticks(
      vec_slice(key, type == "mini"),
      elements$mini, params, position, elements$mini_length, offset
    )
    # Discard zeroGrobs
    grob <- list(major, minor, mini)
    grob <- grob[!map_lgl(grob, is_zero)]
    if (length(grob) == 0) {
      return(zeroGrob())
    }
    gTree(children = inject(gList(!!!grob)))
  },

  draw = function(self, theme, position = NULL, direction = NULL,
                  params = self$params) {

    params <- replace_null(params, position = position, direction = direction)
    params <- self$setup_params(params)

    elems <- self$setup_elements(params, self$elements, theme)
    elems <- self$override_elements(params, elems, theme)
    ticks <- self$build_ticks(params$key, elems, params)

    # If ticks have negative length, we want to preserve reasonable spacing
    # to text labels.
    ticks <- list(ticks, zeroGrob())
    size <- unit(c(elems$size[2], max(0, -1 * diff(elems$size))), "cm")

    primitive_grob(
      grob = ticks,
      size = size,
      position = params$position,
      name = "ticks"
    )
  }
)

# Helpers -----------------------------------------------------------------

draw_ticks = function(key, element, params, position, length, offset = 0) {
  n_breaks <- nrow(key)
  if (n_breaks < 1 || is_blank(element) || all(length == 0)) {
    return(zeroGrob())
  }
  length <- rep(length, length.out = n_breaks)
  bidi <- c(1, -as.numeric(params$bidi %||% FALSE))
  if (is_theta(position)) {
    angle  <- rep(key$theta, each = 2)
    x      <- rep(key$x,     each = 2)
    y      <- rep(key$y,     each = 2)

    length <- rep(length, length.out = n_breaks * 2)
    length <- rep(bidi, times = n_breaks) * length
    length <- unit(length + offset, "cm")

    ticks <- element_grob(
      element,
      x = unit(x, "npc") + sin(angle) * length,
      y = unit(y, "npc") + cos(angle) * length,
      id.lengths = rep(2, n_breaks)
    )
    return(ticks)
  }
  aes <- params$aesthetic
  aes <- switch(
    aes, x = "x", y = "y",
    switch(params$direction, horizontal = "x", "y")
  )

  mark <- unit(rep(key[[aes]], each = 2), "npc")

  pos <- switch(position, top = , right = 0, left = , bottom = 1)
  dir <- (-2 * pos + 1) * bidi
  pos <- unit(rep(pos, 2 * n_breaks), "npc")
  tick <- unit(rep(dir, n_breaks) * rep(length, each = 2), "cm") + pos

  args <- list(x = tick, y = mark, id.lengths = rep(2, n_breaks))
  if (position %in% c("top", "bottom")) {
    args <- flip_names(args)
  }
  inject(element_grob(element, !!!args))
}

zap_tick <- function(elements, name, n) {
  length <- paste0(name, "_length")
  # If there are no ticks, set the element to NULL
  if (n < 1) {
    elements[[name]] <- NULL
  }
  # If there is no element, set the length to 0
  if (is_blank(elements[[name]])) {
    elements[[length]] <- 0
  }
  # Ensure tick lengths are in centimetres
  elements[[length]] <- cm(elements[[length]])
  elements
}
