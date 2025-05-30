# Constructor -------------------------------------------------------------

#' Guide composition
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Guide composition is a meta-guide orchestrating an ensemble of other guides.
#' On their own, a 'composing' guide is not very useful as a visual reflection
#' of a scale.
#'
#' @param guides A `<list>` of guides wherein each element is one of the
#'   following:
#'   * A `<Guide>` class object.
#'   * A `<function>` that returns a `<Guide>` class object.
#'   * A `<character[1]>` naming such a function, without the `guide_` or
#'   `primitive_` prefix.
#' @param args A `<list>` of arguments to pass to guides that are given either
#'   as a function or as a string.
#' @param ... Additional parameters to pass on to
#'   [`new_guide()`][ggplot2::new_guide].
#' @param available_aes A `<character>` giving aesthetics that must match the
#'   the guides.
#' @param super A `<Compose>` class object giving a meta-guide for composition.
#' @param call A [call][rlang::topic-error-call] to display in messages.
#'
#' @name guide-composition
#' @return A `<Compose>` (sub-)class guide that composes other guides.
#' @export
#' @family composition
#'
#' @examples
#' # The `new_compose()` function is not intended to be used directly
#' my_composition <- new_compose(list("axis", "axis"), super = ComposeStack)
#'
#' # Is the same as
#' my_composition <- compose_stack("axis", "axis")
new_compose <- function(guides, args = list(), ...,
                        available_aes = c("any", "x", "y", "r", "theta"),
                        call = caller_env(), super = Compose) {

  guides <- lapply(guides, validate_guide, args = args, call = call)
  if (length(guides) < 1) {
    cli::cli_abort("There must be at least one guide to compose.", call = call)
  }

  available_aes <- compatible_aes(guides, available_aes)
  guide_params  <- lapply(guides, `[[`, name = "params")

  new_guide(
    guides = guides,
    guide_params = guide_params,
    available_aes = available_aes,
    super = super,
    ...
  )
}

# Class -------------------------------------------------------------------

#' @export
#' @rdname legendry_extensions
#' @format NULL
#' @usage NULL
Compose <- ggproto(
  "Compose", Guide,

  params = new_params(
    guides = list(), guide_params = list(),
    key = NULL, angle = waiver()
  ),

  elements = list(spacing = "legendry.guide.spacing"),

  train = function(self, params = self$params, scale, aesthetic = NULL,
                   title = waiver(), ...) {
    title <- scale$make_title(params$title %|W|% scale$name %|W|% title)
    position  <- params$position  <- params$position %|W|% NULL
    aesthetic <- params$aesthetic <- aesthetic %||% scale$aesthetics[1]
    check_position(position, inside = TRUE, allow_null = TRUE)

    key <- resolve_key(params$key, allow_null = TRUE)
    if (is.function(key)) {
      key <- key(scale, aesthetic %||% scale$aesthetics[1])
    }
    params$key <- NULL
    any_title <- FALSE

    guide_params <- params$guide_params
    for (i in seq_along(params$guides)) {
      if (inherits(params$guides[[i]], "PrimitiveTitle")) {
        guide_title <- title
        any_title   <- TRUE
      } else {
        guide_title <- waiver()
      }
      guide_params[[i]]$position <-
        (guide_params[[i]]$position %|W|% NULL) %||% position
      guide_params[[i]]$angle <- guide_params[[i]]$angle %|W|% params$angle
      guide_params[[i]]["key"] <- list(guide_params[[i]]$key %||% key)
      guide_params[[i]] <- params$guides[[i]]$train(
        params = guide_params[[i]], scale = scale, aesthetic = aesthetic,
        title = guide_title, ...
      )
    }
    if (any_title) {
      params$title <- NULL
    } else {
      params$title <- title
    }
    params$guide_params <- guide_params
    params$hash <- hash(lapply(guide_params, get_hash))
    params
  },

  transform = function(self, params, coord, panel_params) {
    params$guide_params <- loop_guides(
      params$guides, params$guide_params, "transform",
      coord = coord, panel_params = panel_params
    )
    params
  },

  get_layer_key = function(params, layers, data = NULL, ...) {
    params$guide_params <- loop_guides(
      params$guides, params$guide_params, "get_layer_key",
      layers = layers, data = data, ...
    )
    # Collect limits
    limits <- get_limits(params)
    params <- set_limits(params, limits)
    params
  },

  draw = function(...) {
    cli::cli_abort("Not implemented.")
  }
)

# Helpers -----------------------------------------------------------------

loop_guides <- function(guides, params, method, ...) {
  for (i in seq_along(guides)) {
    params[[i]] <- guides[[i]][[method]](params = params[[i]], ...)
  }
  params
}

compatible_aes <- function(guides, available_aes, call = caller_env()) {

  valid <- !map_lgl(guides, inherits, what = "GuideNone")
  available <- lapply(guides[valid], `[[`, name = "available_aes")
  common <- Reduce(any_intersect, available)

  if (length(common) < 1) {
    cli::cli_abort(
      "The guides to combine have no shared {.field available aesthetics}.",
      call = call
    )
  }
  if (!is.null(available_aes)) {
    common <- any_intersect(available_aes, common)
    if (length(common) < 1) {
      cli::cli_abort(c(
        "The guides have incompatible {.arg available_aes} settings.",
        "They must include {.or {.val {available_aes}}}."
      ), call  = call)
    }
  }
  common
}

any_intersect <- function(x, y) {
  if ("any" %in% x) {
    x <- union(x, setdiff(y, c("x", "y", "r", "theta")))
  }
  if ("any" %in% y) {
    y <- union(y, setdiff(x, c("x", "y", "r", 'theta')))
  }
  intersect(x, y)
}

validate_guide <- function(guide, args = list(), env = global_env(),
                           call = caller_env()) {
  input <- guide
  if (is.character(guide)) {
    guide <- find_global(paste0("guide_", input), env = env, mode = "function")
  }
  if (is.null(guide) && is.character(input)) {
    guide <- find_global(paste0("primitive_", input), env = env, mode = "function")
  }
  if (is.function(guide)) {
    args  <- args[intersect(names(args), fn_fmls_names(guide))]
    guide <- inject(guide(!!!args))
  }
  if (is_guide(guide)) {
    return(guide)
  }
  cli::cli_abort("Unknown guide: {input}.", call = call)
}

accumulate_limits <- function(...) {
  args <- list2(...)
  args <- args[lengths(args) > 0]
  if (length(args) == 0) {
    return(NULL)
  }
  if (is.character(args[[1]])) {
    unique(unlist(args))
  } else {
    inject(range(!!!args, na.rm = TRUE))
  }
}

get_limits <- function(params) {
  if ("guide_params" %in% names(params)) {
    limits <- lapply(params$guide_params, get_limits)
    accumulate_limits(!!!limits)
  } else {
    params$limits
  }
}

set_limits <- function(params, limits) {
  if ("guide_params" %in% names(params)) {
    params$guide_params <- lapply(params$guide_params, set_limits, limits = limits)
  }
  params$limits <- limits
  params
}

get_hash <- function(x) x$hash
