setwd("C:/Users/dduat/OneDrive/Documentos/Crossmodal_SL")

library(readr)
library(tidyverse)


oddball <- read_csv("csvs/oddballs.csv",col_types = cols())
oddball$subject = factor(oddball$subject, ordered=TRUE)
oddball$modality = factor(oddball$modality,labels=c("V","A"))
oddball$leading = factor(oddball$leading,labels=c("Leading","Trailing"))
oddball$pair_modality = factor(oddball$pair_modality, labels=c("AA","VV","AV","VA"))
oddball$next_mod = factor(oddball$next_mod,labels=c("V","A")) #the modality of the following stimulus (probably not useful)
oddball$mod_switch = factor(oddball$mod_switch) #modality switch right before oddball?
oddball$modal_comb <- "multisensory" #conditions aggregated into multimodal/unimodal
oddball$modal_comb[oddball$pair_modality == "AA" | oddball$pair_modality == "VV"] <- "unisensory"
oddball$stimulus = factor(oddball$stimulus)
oddball$pair = factor(oddball$pair)
head(oddball)

#loading keypresses info
keypresses <- read_csv("csvs/keypresses.csv",col_types = cols())
keypresses$subject = factor(keypresses$subject, ordered=TRUE)

shortest_rt <- 0.15
longest_rt <- 1

oddball <- oddball %>%
  mutate( closest_press = 
            map_dbl(oddball$onset, function(x) which(keypresses$time-(x + shortest_rt)>=0)[1])) %>%
  mutate( rt = keypresses$time[closest_press]-onset) %>%
  replace_na(list(rt = Inf)) %>%
  mutate( detected = rt < longest_rt)

recall <- sum(oddball$detected)/nrow(oddball)

precision <- sum(oddball$detected)/nrow(keypresses)
