library(dplyr)
sink("analysis.output")

data <- read.csv("./data/all-tracks.csv")

make_model <- function(uncharted_adj, cutoff, include_singles, include_bonus, print=FALSE) {

  model_data <- data %>% group_by(album) %>% mutate(album_pos = row_number(album))
  model_data <- subset(model_data, isAltVersion == 0)
  model_data <- subset(model_data, album_pos <= cutoff)
  if (!include_bonus) model_data <- subset(model_data, isBonus == 0)
  if (!include_singles) model_data <- subset(model_data, isSingle == 0)
  model_data$peak <- replace(model_data$peak, model_data$peak<1, uncharted_adj)

  if (print) cat(paste(
    "Modelling data,", length(model_data$name), "items.",
    "\n\tUncharted song constant:", uncharted_adj,
    "\n\tTrack position cutoff:", cutoff,
    if (include_singles) "\n\tIncluding" else "\n\tExcluding", "singles",
    if (include_bonus) "\n\tIncluding" else "\n\tExcluding", "bonus tracks",
    "\n"
  ))

  tracks <- model_data %>% group_by(album_pos) %>% summarise(mean=mean(peak),n=length(which(peak <= 100)))
  model <- lm(mean~album_pos, tracks)
  if (print) print(summary(model))
  return (list(summary(model), model, tracks))
}

make_adjusted_model <- function(uncharted_adj, cutoff, include_singles, include_bonus, print=FALSE) {

  model_data <- data %>% group_by(album) %>% mutate(album_pos = row_number(album))
  model_data$peak <- replace(model_data$peak, model_data$peak<1, uncharted_adj)
  model_data <- model_data %>% arrange(peak)
  model_data <- model_data %>% group_by(album) %>% mutate(peak_adj = row_number(album))  
  model_data <- subset(model_data, isAltVersion == 0)
  model_data <- subset(model_data, album_pos <= cutoff)
  if (!include_bonus) model_data <- subset(model_data, isBonus == 0)
  if (!include_singles) model_data <- subset(model_data, isSingle == 0)

  if (print) cat(paste(
    "Modelling ranked data,", length(model_data$name), "items.",
    "\n\tUncharted song constant:", uncharted_adj,
    "\n\tTrack position cutoff:", cutoff,
    if (include_singles) "\n\tIncluding" else "\n\tExcluding", "singles",
    if (include_bonus) "\n\tIncluding" else "\n\tExcluding", "bonus tracks",
    "\n"
  ))

  tracks <- model_data %>% group_by(album_pos) %>% summarise(mean=mean(peak_adj),n=length(which(peak <= 100)))
  model <- lm(mean~album_pos, tracks)
  if (print) print(summary(model))
  return (list(summary(model), model, tracks))
}

plot_best_model <- function(generate_model, ranked=FALSE, filename=NULL) {
  cutoffs <- list(10, 16, 20, 1000)
  uncharted_adjs <- list(101, 120, 150, 200)

  models <- c()
  for (ua in uncharted_adjs) {
    for (c in cutoffs) {
      for (s in 0:1) {
        for (b in 0:1) {
          r.squared <- generate_model(ua, c, s, b)[[1]]$r.squared
          models <- append(models, c(r.squared, ua, c, s, b))
        }
      }
    }
  }

  models <- data.frame(t(array(models, dim=c(5,64))))
  dimnames(models)[[2]]<- c("r.squared","uncharted","cutoff","singles","bonus")
  print(models)

  cat("\n***Optimized Model***\n\n")
  best <- head(models[order(-models$r.squared),],1)
  best.model <- generate_model(best$uncharted, best$cutoff, best$singles, best$bonus, TRUE)
  best.coefficients <- best.model[[1]]$coefficients[, "Estimate"]
  best.lm <- best.model[[2]]
  best.tracks <- best.model[[3]]

  if (!is.null(filename)) jpeg(paste("plots/", filename, sep=""))
  plot(
    best.tracks$mean,
    ylab=paste("Average ", if (ranked) "(Ranked) " else "", "Peak Position", sep=""),
    xlab="Track Number",
    main=paste("Average Peak Charting Position ", if (ranked) "(Ranked) " else "", "by Track\nNumber (Billboard Hot 100, Taylor Swift)", sep=""),
  )
  abline(best.lm)
  if (!is.null(filename)) suppress <- dev.off()
}

plot_best_model(make_model, FALSE, "standard.jpg")
plot_best_model(make_adjusted_model, TRUE, "ranked.jpg")

sink()
