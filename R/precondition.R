ensure_not_na <- function(object) {
  if (any(is.na(object))) {
    stopf(
      "'%s' %s",
      deparse(substitute(object)),
      if (length(object) > 1) "contains NA values" else "is NA"
    )
  }

  object
}

ensure_not_null <- function(object) {
  object %||% stop(sprintf("'%s' is NULL", deparse(substitute(object))))
}

#' Enforce Specific Structure for R Objects
#'
#' These routines are useful when preparing to pass objects to
#' a Spark routine, as it is often necessary to ensure certain
#' parameters are scalar integers, or scalar doubles, and so on.
#'
#' @param object An \R object.
#' @param allow.na Are \code{NA} values permitted for this object?
#' @param allow.null Are \code{NULL} values permitted for this object?
#' @param default If \code{object} is \code{NULL}, what value should
#'   be used in its place? If \code{default} is specified, \code{allow.null}
#'   is ignored (and assumed to be \code{TRUE}).
#'
#' @name ensure
#' @rdname ensure
NULL

make_ensure_scalar_impl <- function(checker,
                                    message,
                                    converter)
{
  fn <- function(object,
                 allow.na = FALSE,
                 allow.null = FALSE,
                 default = NULL)
  {
    warning("`ensure_*` functions are deprecated and will be removed in a future release. Please use package 'forge' instead.",
            call. = FALSE)
    object <- object %||% default

    if (allow.null && is.null(object)) return(object)

    if (!checker(object))
      stopf("'%s' is not %s", deparse(substitute(object)), message)

    if (is.na(object)) object <- NA_integer_
    if (!allow.na)     ensure_not_na(object)
    if (!allow.null)   ensure_not_null(object)

    converter(object)
  }

  environment(fn) <- parent.frame()

  body(fn) <- do.call(
    substitute,
    list(
      body(fn),
      list(
        checker = substitute(checker),
        message = substitute(message),
        converter = substitute(converter)
      )
    )
  )

  fn
}

#' @rdname ensure
#' @name ensure
#' @export
ensure_scalar_integer <- make_ensure_scalar_impl(
  is.numeric,
  "a length-one integer vector",
  as.integer
)

#' @rdname ensure
#' @name ensure
#' @export
ensure_scalar_double <- make_ensure_scalar_impl(
  is.numeric,
  "a length-one numeric vector",
  as.double
)

#' @rdname ensure
#' @name ensure
#' @export
ensure_scalar_boolean <- make_ensure_scalar_impl(
  is.logical,
  "a length-one logical vector",
  as.logical
)

#' @rdname ensure
#' @name ensure
#' @export
ensure_scalar_character <- make_ensure_scalar_impl(
  is.character,
  "a length-one character vector",
  as.character
)


require_file_exists <- function(path, fmt = NULL) {
  fmt <- fmt %||% "no file at path '%s'"
  if (!file.exists(path)) stopf(fmt, path)
  path
}

require_directory_exists <- function(path, fmt = NULL) {
  fmt <- fmt %||% "no file at path '%s'"
  require_file_exists(path)
  info <- file.info(path)
  if (!isTRUE(info$isdir)) stopf(fmt, path)
  path
}

ensure_directory <- function(path) {

  if (file.exists(path)) {
    info <- file.info(path)
    if (isTRUE(info$isdir)) return(path)
    stopf("path '%s' exists but is not a directory", path)
  }

  if (!dir.create(path, recursive = TRUE))
    stopf("failed to create directory at path '%s'", path)

  invisible(path)

}
