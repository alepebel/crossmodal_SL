---
title: "analysis_oddball_RT"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## Analysis of oddball detection RTs

```{r include=FALSE}

setwd('/Users/alex/Dropbox/PROJECTS/MS_Statistical_learning/R/Exp_1')
#setwd("~/TFM2/TFM_experiment_sandbox")
#setwd("C:/toolbox/TFM_experiment_sandbox")
```

```{r include=FALSE}
library(readr)
library(tidyverse)
```

```{r echo=FALSE}
oddball <- read_csv('/Users/alex/Dropbox/PROJECTS/MS_Statistical_learning/Behavioral/Exp_1/csv/exposure_oddballs.csv',col_types = cols())
oddball$subject = factor(oddball$subject, ordered=TRUE)
oddball$modality = factor(oddball$modality,labels=c("Visual","Auditory"))
oddball$leading = factor(oddball$leading,labels=c("Leading","Trailing"))
when <- cbind(
  oddball$block<3,
  oddball$block==3,
  oddball$block>3
)
oddball$when = factor(max.col(when),labels=c("Early","Mid", "Late"))
oddball$pair_modality = factor(oddball$pair_modality, labels=c("Auditory","Visual","AudioVis","VisAudio"))
oddball$next_mod = factor(oddball$next_mod,labels=c("Visual","Auditory"))
#oddball$mod_switch = factor(oddball$mod_switch)
#conditions aggregated into multimodal/unimodal
oddball$modal_comb <- "multisensory"
oddball$modal_comb[oddball$pair_modality == "Auditory" | oddball$pair_modality == "Visual"] <- "unisensory"
oddball$stimulus = factor(oddball$stimulus)
oddball$pair = factor(oddball$pair)
head(oddball)

#loading subjects info
subjects <- read_csv("Behavioral/Exp_1/csv/subjects_info.csv",col_types = cols())
subjects$subject = factor(subjects$subject, ordered=TRUE)
subjects$order = factor(subjects$order)
subjects$music = factor(subjects$music)
subjects$gender = factor(subjects$gender)
subjects$hand = factor(subjects$hand)
```

We first filter out trials with unplausible RTs: less than 150ms is too fast to be a real answer and more than 1 second is probably an answer to the next stimulus.
```{r}
xoddball <- subset(oddball, rt < 1 & oddball$rt > 0.15)
```