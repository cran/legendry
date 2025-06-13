# Constructor -------------------------------------------------------------

#' Guide primitive: line
#'
#' This function constructs a line [guide primitive][guide-primitives].
#'
#' @param cap A method to cap the axes. One of the following:
#'   * A `<character[1]>` with one of the following:
#'     * `"none"` to perform no capping.
#'     * `"both"` to cap the line at both ends at the most extreme breaks.
#'     * `"upper"` to cap the line at the upper extreme break.
#'     * `"lower"` to cap the line at the lower extreme break.
#'   * A `<logical>[1]`, where `TRUE` is equivalent to `"both"` and `FALSE`
#'   is equivalent to `"none"` in the options above.
#'   * A sorted `<numeric>[2n]` with an even number of members. The lines
#'   will be drawn between every odd-even pair.
#'   * A `<function>` that takes the scale's breaks as the first argument, the
#'   scale's limits as the second argument and returns a `<numeric>[2n]` as
#'   described above.
#' @inheritParams primitive_labels
#'
#' @return A `PrimitiveLine` primitive guide that can be used inside other
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
#' ## As an axis guide
#'
#' * `axis.line.{x/y}.{position}` an [`<element_line>`][ggplot2::element_line]
#'   for the line style.
#'
#' ## As a legend guide
#'
#' * `legend.axis.line` an [`<element_line>`][ggplot2::element_line] for the
#'   line style.
#'
#' @examples
#' # A standard plot
#' p <- ggplot(mpg, aes(displ, hwy)) +
#'   geom_point() +
#'   theme(axis.line = element_line())
#'
#' # Adding as secondary guides
#' p + guides(
#'   x.sec = primitive_line(),
#'   y.sec = primitive_line(cap = "both")
#' )
primitive_line <- function(key = NULL, cap = "none", theme = NULL,
                       position = waiver()) {
  new_guide(
    key = key,
    cap = check_cap_arg(cap),
    theme = theme,
    position = position,
    available_aes = c("any", "x", "y", "r", "theta"),
    super = PrimitiveLine
  )
}

# Class -------------------------------------------------------------------

#' @export
#' @rdname legendry_extensions
#' @format NULL
#' @usage NULL
PrimitiveLine <- ggproto(
  "PrimitiveLine", Guide,

  params = new_params(cap = c(-Inf, Inf), key = NULL),

  elements = list(
    position = list(line = "axis.line"),
    legend   = list(line = "legend.axis.line")
  ),

  hashables = exprs(decor[[aesthetic]], get0("position")),

  extract_key = standard_extract_key,

  extract_decor = function(scale, aesthetic, position, cap, key, ...) {
    limits <- scale$continuous_range %||% scale$get_limits()
    if (is.function(cap)) {
      if (length(fn_fmls_names(cap)) == 1) {
        cap <- cap(key[[aesthetic]])
      } else {
        cap <- cap(key[[aesthetic]], limits)
      }
    }

    decor <- data_frame(!!aesthetic := cap)
    if (aesthetic %in% c("x", "y")) {
      opposite <- setdiff(c("x", "y"), aesthetic)
      position <-
        switch(position, theta = "left", theta.sec = "right", position)
      value <- if (position %in% c("top", "right")) -Inf else Inf
      decor[[opposite]] <- value
    } else {
      value <- scale$oob(decor[[aesthetic]], range = limits)
      decor[[aesthetic]] <- value
    }

    group <- seq_len(ceiling(nrow(decor) / 2))
    decor$group <- rep(group, each = 2, length.out = nrow(decor))
    decor
  },

  extract_params = primitive_extract_params,

  transform = function(self, params, coord, panel_params) {
    params$decor <- coord_munch(coord, params$decor, panel_params)
    params
  },

  setup_elements = primitive_setup_elements,

  build_decor = function(decor, grobs, elements, params) {
    if (is_empty(decor)) {
      return(zeroGrob())
    }
    x <- y <- NULL
    if ("theta" %in% names(decor)) {
      theta  <- decor$theta + as.numeric(params$position == "theta.sec") * pi
      offset <- elements$offset
      x <- unit(decor$x, "npc") + unit(sin(theta) * offset, "cm")
      y <- unit(decor$y, "npc") + unit(cos(theta) * offset, "cm")
    }
    if (!all(c("x", "y") %in% names(decor))) {
      value <- guide_rescale(decor[[params$aesthetic]], params$limits)
      if (params$position %in% c("left", "right")) {
        y <- unit(value, "npc")
        x <- as.numeric(params$position == "left") |>
          rep(length.out = length(y)) |> unit("npc")
      } else {
        x <- unit(value, "npc")
        y <- as.numeric(params$position == "bottom") |>
          rep(length.out = length(x)) |> unit("npc")
      }
    }
    element_grob(
      elements$line,
      x = x %||% unit(decor$x, "npc"),
      y = y %||% unit(decor$y, "npc"),
      id.lengths = vctrs::vec_unrep(decor$group)$times
    )
  },

  draw = function(self, theme, position = NULL, direction = NULL,
                  params = self$params) {

    params <- replace_null(params, position = position, direction = direction)

    elems <- self$setup_elements(params, self$elements, theme)
    decor <- self$build_decor(params$decor, grobs, elems, params)

    primitive_grob(
      grob = decor,
      size = unit(0, "cm"),
      position = params$position,
      name = "line"
    )
  }
)

# Helpers -----------------------------------------------------------------

check_cap_arg <- function(cap, call = caller_env()) {
  if (is.logical(cap)) {
    check_bool(cap)
    cap <- if (cap) "both" else "none"
  }
  if (is.character(cap)) {
    cap <- switch(
      cap,
      "none"  = c(-Inf, Inf),
      "both"  = function(breaks, limits) range(breaks, na.rm = TRUE),
      "upper" = function(breaks, limits) c(limits[1], max(breaks, na.rm = TRUE)),
      "lower" = function(breaks, limits) c(min(breaks, na.rm = TRUE), limits[2]),
      arg_match0(cap, c("none", "both", "upper", "lower"))
    )
  }
  if (!is.function(cap) && !vctrs::vec_is(cap)) {
    stop_input_type(cap, what = as_cli("a {.cls function} or {.cls vector}"))
  }
  cap
}
