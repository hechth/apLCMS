proc.cdf <- function(filename, min.pres = 0.5, min.run = 12, tol = 1e-5, baseline.correct = 0, baseline.correct.noise.percentile = 0, do.plot = TRUE, intensity.weighted = FALSE) {
  this <- load.lcms(filename)

  na.sel <- c(which(is.na(this$masses)), which(is.na(this$labels)), which(is.na(this$intensi)))
  if (length(na.sel) > 0) {
    warning("there are NA values in the m/z or intensity. Check the file:", filename)

    na.sel <- unique(na.sel)
    this$masses <- this$masses[-na.sel]
    this$labels <- this$labels[-na.sel]
    this$intensi <- this$intensi[-na.sel]
  }
  raw.prof <- adaptive.bin(this, min.run = min.run, min.pres = min.pres, tol = tol, baseline.correct = baseline.correct, weighted = intensity.weighted)

  newprof <- cbind(raw.prof$masses, raw.prof$labels, raw.prof$intensi, raw.prof$grps)
  h.1 <- log10(raw.prof$height.rec[raw.prof$height.rec[, 2] <= max(2, raw.prof$min.count.run * min.pres / 2), 3])
  h.2 <- log10(raw.prof$height.rec[raw.prof$height.rec[, 2] >= raw.prof$min.count.run * min.pres, 3])

  if (is.na(baseline.correct)) {
    baseline.correct <- 10 ^ quantile(h.1, baseline.correct.noise.percentile)
    message(c("maximal height cut is automatically set at the", baseline.correct.noise.percentile, "percentile of noise group heights: ", baseline.correct))
  } else {
    message(c("maximal height cut is provided by user: ", baseline.correct))
  }

  run.sel <- raw.prof$height.rec[which(raw.prof$height.rec[, 2] >= raw.prof$min.count.run * min.pres & raw.prof$height.rec[, 3] > baseline.correct), 1]
  newprof <- newprof[newprof[, 4] %in% run.sel,]
  new.prof <- cont.index(newprof, min.pres = min.pres, min.run = min.run)

  if (do.plot) {
    par(mfrow = c(2, 2))

    if (length(h.1) > 50) {
      plot(density(h.1), xlab = "maximum height of group (log scale)", xlim = range(c(h.1, h.2)), main = "Black - noise groups \n Blue - selected groups")
    } else {
      plot(NA, NA, xlab = "maximum height of group (log scale)", xlim = range(c(h.1, h.2)), ylim = c(0, 1), main = "Black - noise groups \n Blue - selected groups")
      if (length(h.1) > 0) abline(v = h.1)
    }

    abline(v = log10(baseline.correct), col = "red")
    lines(density(log10(new.prof$height.rec)), col = "blue")
    hist(new.prof$time.range.rec, xlab = "Range of retention time in the same group", ylab = "Density", freq = FALSE, nclass = 100, main = "Group retention time range distribution")
    hist(new.prof$mz.pres.rec, xlab = "% signal present in the same group", ylab = "Density", freq = FALSE, nclass = 20, main = "Group % present signal distribution")
  }

  return(new.prof$new.rec)
}
