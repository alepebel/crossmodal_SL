setwd("/Users/alex/Dropbox/PROJECTS/MS_Statistical_learning/R/Exp_1")

library(readr)
library(tidyverse)


oddball <- read_csv('/Users/alex/Dropbox/PROJECTS/MS_Statistical_learning/Behavioral/Exp_1/csv/exposure_oddballs.csv',col_types = cols())
oddball$subject = factor(oddball$subject, ordered=TRUE)
oddball$modality = factor(oddball$modality,labels=c("V","A"))
oddball$leading = factor(oddball$leading,labels=c("Leading","Trailing"))
oddball$pair_modality = factor(oddball$pair_modality, labels=c("AA","VV","AV","VA"))
oddball$next_mod = factor(oddball$next_mod,labels=c("V","A")) #the modality of the following stimulus (probably not useful)
oddball$modal_comb <- "multisensory" #conditions aggregated into multimodal/unimodal
oddball$modal_comb[oddball$pair_modality == "AA" | oddball$pair_modality == "VV"] <- "unisensory"
oddball$stimulus = factor(oddball$stimulus)
oddball$pair = factor(oddball$pair)
oddball$mod_switch = factor(oddball$mod_switch)
head(oddball)

#loading keypresses info
keypresses <- read_csv("/Users/alex/Dropbox/PROJECTS/MS_Statistical_learning/Behavioral/Exp_1/csv/exposure_keypresses.csv",col_types = cols())
keypresses$subject = factor(keypresses$subject, ordered=TRUE)

shortest_rt <- 0.15
longest_rt <- 1.5

oddball <- oddball %>%
  mutate( closest_press = 
            map_dbl(oddball$onset, function(x) which(keypresses$time-(x + shortest_rt)>=0)[1])) %>%
  mutate( rt = keypresses$time[closest_press]-onset) %>%
  replace_na(list(rt = Inf)) %>%
  mutate( detected = rt < longest_rt)


df <- df %>% filter(subj != 3)


group_recall <- oddball %>% 
  group_by( subject, modality) %>% 
  summarise(correct = mean(detected))



ggplot(subset(group_recall), aes(x=factor(modality), y=correct, col = modality, fill = factor(modality))) + 
  geom_violin(col = NA, alpha = 0.3,trim=FALSE) +scale_color_manual( values =  c("blue","orange")) + scale_fill_manual( values =  c("blue","orange")) +
  geom_line(data=group_recall,aes(modality,correct,group = subject), col = "darkgrey", size = 0.3) +
  geom_point( size = 2,  position = position_jitter(w = 0.1, h = 0)) +
  geom_boxplot( coef = 1.5, outlier.size=0 , col = "black", fill="NA", width = 0.2) +
  # scale_y_continuous(limits=c(0.0,3), breaks = c(0, 1, 2, 3)) +
  theme_bw(20) + #   facet_grid(.~Vfield) + 
  theme(axis.text=element_text(size=16), axis.title=element_text(size=14),axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank()) #+

df <- df %>% group_by(subj,block,trial) %>% mutate(respcat = ifelse(resp1 <3,0,1),
                                                   sumresp = sum(resp1 + resp2))

avg_recall <-aggregate(detected~subject, data = oddball, mean)
avg_recall <-aggregate(detected~subject, data = oddball, sum)
avg_keypress <- aggregate(time~subject, data = keypresses, length)

subjs_precision <-cbind(avg_recall, time = avg_keypress$time) %>%
  mutate(precision = detected/time) %>% mutate(learner = ifelse(precision > median(precision), 1, 0))
  



group_recall_by_block <- oddball %>% 
  group_by( subject, block, pair_modality,leading, mod_switch) %>% 
  summarise(correct = mean(detected))

ggplot(subset(group_recall_by_block), aes(x=(block), y=correct, col = leading, fill = factor(leading))) + 
  scale_color_manual( values =  c("blue","orange")) + scale_fill_manual( values =  c("blue","orange")) +
  geom_point( size = 2,  position = position_jitter(w = 0.1, h = 0)) + facet_grid(pair_modality~mod_switch) + 
  stat_smooth() +
  theme_bw(20) + #   facet_grid(.~Vfield) + 
  theme(axis.text=element_text(size=16), axis.title=element_text(size=14),axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank())

group_recall_by_block <- oddball %>% 
  group_by( subject, block, modality,leading, mod_switch) %>% 
  summarise(correct = mean(detected), rt = mean(rt))

ggplot(subset(group_recall_by_block), aes(x=(block), y=correct, col = leading, fill = factor(leading))) + 
  scale_color_manual( values =  c("blue","orange")) + scale_fill_manual( values =  c("blue","orange")) +
  geom_point( size = 2,  position = position_jitter(w = 0.1, h = 0)) + facet_grid(.~mod_switch) + 
  stat_smooth() +
  theme_bw(20) + 
  theme(axis.text=element_text(size=16), axis.title=element_text(size=14),axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank())




ggplot(aes(x=(block),y=(rt),color = leading),data=subset(group_recall_by_block, block != 1)) +  geom_point(size=0.5)  +
  theme_bw(15)    + facet_grid(.~mod_switch) +
  geom_smooth(method="lm",fullrange = TRUE)






group_precision <- oddball %>% 
  group_by( subject, modality) %>% 
  summarise(correct = mean(detected))
sum(oddball$detected)/nrow(keypresses)

ggplot(subset(group_precision), aes(x=factor(modality), y=correct, col = modality, fill = factor(modality))) + 
  geom_violin(col = NA, alpha = 0.3,trim=FALSE) +scale_color_manual( values =  c("blue","orange")) + scale_fill_manual( values =  c("blue","orange")) +
  geom_line(data=group_precision,aes(modality,correct,group = subject), col = "darkgrey", size = 0.3) +
  geom_point( size = 2,  position = position_jitter(w = 0.1, h = 0)) +
  geom_boxplot( coef = 1.5, outlier.size=0 , col = "black", fill="NA", width = 0.2) +
  # scale_y_continuous(limits=c(0.0,3), breaks = c(0, 1, 2, 3)) +
  theme_bw(20) + #   facet_grid(.~Vfield) + 
  theme(axis.text=element_text(size=16), axis.title=element_text(size=14),axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank()) #+

group_precision_by_block <- oddball %>% 
  group_by( subject, block, modality) %>% 
  summarise(correct = mean(detected))

ggplot(subset(group_precision_by_block), aes(x=factor(block), y=correct, col = modality, fill = factor(modality))) + 
  scale_color_manual( values =  c("blue","orange")) + scale_fill_manual( values =  c("blue","orange")) +
  geom_point( size = 2,  position = position_jitter(w = 0.1, h = 0)) + facet_grid(modality~.) + 
  geom_boxplot( coef = 1.5, outlier.size=0 , col = "black", fill="NA", width = 0.2) +
  theme_bw(20) + #   facet_grid(.~Vfield) + 
  theme(axis.text=element_text(size=16), axis.title=element_text(size=14),axis.line = element_line(colour = "black"),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank())

recall <- sum(oddball$detected)/nrow(oddball)




ggplot(subset(keypresses), aes(x=factor(block), y=correct, col = modality, fill = factor(modality))) + 
scale_color_manual( values =  c("blue","orange")) + scale_fill_manual( values =  c("blue","orange"))
       
#lead vs trail in the different conditions
ggplot(aes(x=(order),y=(rt),color = leading),data=subset(oddball)) +  geom_point(size=0.5)  +
  theme_bw(15)    + facet_grid(pair_modality~.) + geom_smooth(method="lm",fullrange = TRUE)

ggplot(aes(x=(order),y=(detected),color = leading),data=subset(oddball)) +  geom_point(size=0.5)  +
  theme_bw(15)    + facet_grid(pair_modality~.) 


#attentional switch vs no attentional switch (only leading)
ggplot(aes(x=(order),y=(rt),color = mod_switch),data=subset(oddball,leading=="Leading")) +  geom_point(size=0.5)  +
  theme_bw(15)    + facet_grid(modality~.) +
  geom_smooth(method="lm",fullrange = TRUE)

#RT(trail_multimodal) vs RT(lead_after_switch) 
ggplot(aes(x=(order),y=(speed_interp),color = leading),data=subset(xoddball_filtered,mod_switch==1 & shifted==0)) +  geom_jitter(size=0.5)  +
  theme_bw(15)    + facet_grid(modality~.) +
  geom_smooth(method="lm",fullrange = TRUE)

#RT(trail_unimodal) vs RT(lead_no_switch) 
ggplot(aes(x=(order),y=(speed_interp),color = leading),data=subset(xoddball_filtered,mod_switch==0)) +  geom_jitter(size=0.5)  +
  theme_bw(15)    + facet_grid(modality~.) +
  geom_smooth(method="lm",fullrange = TRUE)

#Linear mixed-effects models, taking attentional switch into account
fitUniNull <- lmer(speed_interp ~ scale(order)*modality + (1+scale(order)+modality|subject), data=subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0))
fitUni <- lmer(speed_interp ~ scale(order)*leading*modality + (1+scale(order)+modality+leading|subject), data=subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0))
anova(fitUniNull,fitUni)
plot_model(fitUni,type="eff",terms=c("order","leading","modality"))
plot_model(fitUniNull,type="eff",terms=c("order","modality"))

plot(subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0)$speed_interp)
plot(predict(fitUniNull,subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0)))
plot(predict(fitUni,subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0)))

fitMultiNull <- lmer(speed_interp ~ scale(order)*modality + (1+scale(order)+modality|subject), data=subset(xoddball_filtered, modal_comb == "multisensory" & mod_switch==1))
fitMulti <- lmer(speed_interp ~ scale(order)*leading*modality + (1+scale(order)+modality+leading|subject), data=subset(xoddball_filtered, modal_comb == "multisensory" & mod_switch==1))
anova(fitMultiNull,fitMulti)
plot_model(fitMulti,type="eff",terms=c("order","leading","modality"))
plot_model(fitMultiNull,type="eff",terms=c("order","modality"))

plot(subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0)$speed_interp)
plot(predict(fitUni,subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0)))
plot(predict(fitUni,subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0)))

#Alexis-suggested models
fit1Uni <- lmer(speed_interp ~ scale(order) * leading * modality + (1+scale(order)|subject) , data=subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0))
summary(fit1Uni)
anova(fit1Uni)
fit2Uni <- lmer(speed_interp ~ scale(order) * leading * modality + (1 |subject) , data=subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0))
summary(fit2Uni)
anova(fit1Uni,fit2Uni)
plot(predict(fit1Uni),subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0)$speed_interp,
     xlab="predicted",ylab="actual")+abline(a=0,b=1)
plot(predict(fit2Uni),subset(xoddball_filtered, modal_comb == "unisensory" & mod_switch==0)$speed_interp,
     xlab="predicted",ylab="actual")+abline(a=0,b=1)
