#' @title Ordinary Least Squares Forecast Combination
#'
#' @description Computes forecast combination weights using ordinary least squares (OLS) regression.
#'
#' @details
#' The function integrates the ordinary least squares (OLS) forecast combination implementation of the
#' \emph{ForecastCombinations} package into GeomComb.
#'
#' The OLS combination method (Granger and Ramanathan (1984)) uses ordinary least squares to
#' estimate the weights, \eqn{\mathbf{w}^{OLS} = (w_1, \ldots, w_N)'}, as well as an intercept, \eqn{b}, for the combination of
#' the forecasts.
#'
#' Suppose that there are \eqn{N} not perfectly collinear predictors  \eqn{\mathbf{f}_t = (f_{1t}, \ldots, f_{Nt})'},
#' then the forecast combination for one data point can be represented as:
#' \deqn{y_t = b + \sum_{i=1}^{N} w_i f_{it}}
#'
#' An appealing feature of the method is its bias correction through the intercept -- even if one or more of the individual
#' predictors are biased, the resulting combined forecast is unbiased. A disadvantage of the method is that it places no
#' restriction on the combination weights (i.e., they do not add up to 1 and can be negative), which can make interpretation
#' hard. Another issue, documented in Nowotarski et al. (2014), is the method's unstable behavior
#' when predictors are highly correlated (which is the norm in forecast combination): Minor fluctuations in the sample
#' can cause major shifts of the coefficient vector (\sQuote{bouncing betas}) -- often causing poor out-of-sample performance.
#' This issue is addressed by the \code{\link{comb_LAD}} method that is more robust to outliers.
#'
#' The results are stored in an object of class 'foreccomb_res', for which separate plot and summary functions are provided.
#'
#' @param x An object of class 'foreccomb'. Contains training set (actual values + matrix of model forecasts) and optionally a test set.
#'
#' @return Returns an object of class \code{foreccomb_res} with the following components:
#' \item{Method}{Returns the best-fit forecast combination method.}
#' \item{Models}{Returns the individual input models that were used for the forecast combinations.}
#' \item{Weights}{Returns the combination weights obtained by applying the combination method to the training set.}
#' \item{Intercept}{Returns the intercept of the linear regression.}
#' \item{Fitted}{Returns the fitted values of the combination method for the training set.}
#' \item{Accuracy_Train}{Returns range of summary measures of the forecast accuracy for the training set.}
#' \item{Forecasts_Test}{Returns forecasts produced by the combination method for the test set. Only returned if input included a forecast matrix for the test set.}
#' \item{Accuracy_Test}{Returns range of summary measures of the forecast accuracy for the test set. Only returned if input included a forecast matrix and a vector of actual values for the test set.}
#' \item{Input_Data}{Returns the data forwarded to the method.}
#'
#' @examples
#' obs <- rnorm(100)
#' preds <- matrix(rnorm(1000, 1), 100, 10)
#' train_o<-obs[1:80]
#' train_p<-preds[1:80,]
#' test_o<-obs[81:100]
#' test_p<-preds[81:100,]
#'
#' data<-foreccomb(train_o, train_p, test_o, test_p)
#' comb_OLS(data)
#'
#' @seealso
#' \code{\link[ForecastCombinations]{Forecast_comb}},
#' \code{\link{foreccomb}},
#' \code{\link{plot.foreccomb_res}},
#' \code{\link{summary.foreccomb_res}},
#' \code{\link[forecast]{accuracy}}
#'
#' @references
#' Granger, C., and Ramanathan, R. (1984). Improved Methods Of Combining Forecasts. \emph{Journal of Forecasting}, \bold{3(2)}, 197--204.
#'
#' Nowotarski, J., Raviv, E., Tr\"uck, S., and Weron, R. (2014). An Empirical Comparison of Alternative
#' Schemes for Combining Electricity Spot Price Forecasts. \emph{Energy Economics}, \bold{46}, 395--412.
#'
#' @keywords models
#'
#' @import forecast
#'
#' @export
comb_OLS <- function(x) {
    if (class(x) != "foreccomb")
        stop("Data must be class 'foreccomb'. See ?foreccomb, to bring data in correct format.", call. = FALSE)
    observed_vector <- x$Actual_Train
    prediction_matrix <- x$Forecasts_Train
    modelnames <- x$modelnames

    lin_model <- lm(observed_vector ~ prediction_matrix)

    weights <- unname(lin_model$coef[-1])
    intercept <- unname(lin_model$coef[1])
    fitted <- unname(fitted(lin_model))
    accuracy_insample <- accuracy(fitted, observed_vector)

    if (is.null(x$Forecasts_Test) & is.null(x$Actual_Test)) {
        result <- structure(list(Method = "Ordinary Least Squares Regression", Models = modelnames, Weights = weights, Intercept = intercept, Fitted = fitted, Accuracy_Train = accuracy_insample,
            Input_Data = list(Actual_Train = x$Actual_Train, Forecasts_Train = x$Forecasts_Train)), class = c("foreccomb_res"))
        rownames(result$Accuracy_Train) <- "Training Set"
    }

    if (is.null(x$Forecasts_Test) == FALSE) {
        newpred_matrix <- x$Forecasts_Test
        pred <- as.vector(lin_model$coef %*% t(cbind(1, newpred_matrix)))
        if (is.null(x$Actual_Test) == TRUE) {
            result <- structure(list(Method = "Ordinary Least Squares Regression", Models = modelnames, Weights = weights, Intercept = intercept, Fitted = fitted, Accuracy_Train = accuracy_insample,
                Forecasts_Test = pred, Input_Data = list(Actual_Train = x$Actual_Train, Forecasts_Train = x$Forecasts_Train, Forecasts_Test = x$Forecasts_Test)), class = c("foreccomb_res"))
            rownames(result$Accuracy_Train) <- "Training Set"
        } else {
            newobs_vector <- x$Actual_Test
            accuracy_outsample <- accuracy(pred, newobs_vector)
            result <- structure(list(Method = "Ordinary Least Squares Regression", Models = modelnames, Weights = weights, Intercept = intercept, Fitted = fitted, Accuracy_Train = accuracy_insample,
                Forecasts_Test = pred, Accuracy_Test = accuracy_outsample, Input_Data = list(Actual_Train = x$Actual_Train, Forecasts_Train = x$Forecasts_Train, Actual_Test = x$Actual_Test,
                  Forecasts_Test = x$Forecasts_Test)), class = c("foreccomb_res"))
            rownames(result$Accuracy_Train) <- "Training Set"
            rownames(result$Accuracy_Test) <- "Test Set"
        }
    }
    return(result)
}
