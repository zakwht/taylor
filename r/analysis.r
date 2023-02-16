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

heat_plot <- function(tracks, cuts, trackName=FALSE) {
  par(mar = c(0,0,0,0))
  plot.new()
  for (i in 1:length(tracks$mean)) { 
    int <- 1 / length(tracks$mean)
    row <- tracks[i,]
    j <- int * row$album_pos
    labs <- c("darkred", "red", "orange", "yellow", "white")
    color <- labs[findInterval(row$mean, cuts)]

    polygon(
      c(0,1,1,0),
      c(1-j, 1-j, (1+int)-j, (1+int)-j),
      col=color
    )
    text(
      if (trackName) 0.9 else 0.5,
      1 + ( 0.4 * int) - j,
      if (row$mean == 101) "-" else round(row$mean,3)
    ) 
    text(
      0.04,
      1 + ( 0.4 * int) - j,
      paste(i, ". ", if (trackName) row$name else "", sep=""),
      pos=4
    )
  }
}

plot_best_model <- function(generate_model, ranked=FALSE, filename=NULL, default=FALSE) {
  cutoffs <- list(10, 16, 20, 1000)
  uncharted_adjs <- list(101, 120, 150, 200)

  models <- c()
  if (default) {
    r.squared <- generate_model(101, 1000, 1, 1)[[1]]$r.squared
    models <- append(models, c(r.squared, 101, 1000, 1, 1))
  } else {
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
  }

  models <- data.frame(t(array(models, dim=c(5,64))))
  dimnames(models)[[2]]<- c("r.squared","uncharted","cutoff","singles","bonus")
  if (!default) print(models)

  if (!default) cat("\n***Optimized Model***\n\n")
  best <- head(models[order(-models$r.squared),],1)
  best.model <- generate_model(best$uncharted, best$cutoff, best$singles, best$bonus, !default)
  best.coefficients <- best.model[[1]]$coefficients[, "Estimate"]
  best.lm <- best.model[[2]]
  best.tracks <- best.model[[3]]

  if (!is.null(filename)) jpeg(paste("plots/", filename, "-heat.jpg", sep=""))
  heat_plot(
    best.tracks, 
    if (ranked) c(-Inf, 5, 10, 15, 20, Inf) else if (default) c(-Inf, 21, 40, 60, 100, Inf) else c(-Inf, 20, 50, 75, 100, Inf)
  )
  if (!is.null(filename)) suppress <- dev.off()

  if (!is.null(filename)) jpeg(paste("plots/", filename, ".jpg", sep=""))
  plot(
    best.tracks$mean,
    ylab=paste("Average ", if (ranked) "(Ranked) " else "", "Peak Position", sep=""),
    xlab="Track Number",
    main=paste("Average Peak Charting Position ", if (ranked) "(Ranked) " else "", "by Track\nNumber (Billboard Hot 100, Taylor Swift)", sep=""),
  )
  abline(best.lm)
  if (!is.null(filename)) suppress <- dev.off()
}

album_heat_maps <- function() {
  all_tracks <- subset(data, isAltVersion == 0) %>% group_by(album) %>% mutate(mean = peak) %>% arrange(albumIndex) %>% mutate(album_pos = row_number(album))
  all_tracks$mean <- replace(all_tracks$mean, all_tracks$mean<1, 101)

  for (i in unique(tracks$albumIndex)) {
    album_tracks <- subset(all_tracks, albumIndex == i)
    jpeg(paste("plots/albums/", sprintf("%02s", i), ".jpg", sep=""))
    heat_plot(album_tracks, c(-Inf, 1.1, 10.1, 40.1, 100.1, Inf), TRUE)
    supress <- dev.off()
  }
}

plot_best_model(make_model, FALSE, "standard")
plot_best_model(make_adjusted_model, TRUE, "ranked")
plot_best_model(make_model, FALSE, "all", default=TRUE)
album_heat_maps()

sink()
