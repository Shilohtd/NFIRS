data.dir <- "/home/dchelst/Public_Data/NFIRS/NFIRS2014"
setwd(data.dir)
load(file.path(data.dir, "NFIRS2014.RData"))

## Quick mutual aid summary
# 1: mutual aid calls in basic data file

aid.count <- nfirs.data$basic %>% 
  count(AID) %>%
  ungroup %>%
  mutate(fieldid="AID") %>%
  left_join(nfirs.data$codes, by=c("fieldid", "AID"="code_value")) %>%
  select(AID, code_descr, n) %>%
  mutate(percent = 100 * n / sum(n))

aid.df <- data_frame(AID=c(1:5, "N"), 
                     AID2=rep(c("received", "given", "alone"), c(2, 3, 1)))

aid.count.detail <- nfirs.data$basic %>% 
  left_join(aid.df, by="AID") %>%
  count(INC_TYPE, AID2) %>%
  ungroup %>%
  spread(AID2, n, fill=0) %>% 
  mutate(fieldid="INC_TYPE") %>%
  left_join(nfirs.data$codes, by=c("fieldid", "INC_TYPE"="code_value")) %>%
  select(INC_TYPE, code_descr, received, given, alone) 
aid.count.detail <- aid.count.detail %>% 
  select(received:alone) %>% 
  colSums %>% 
  t %>% 
  as.data.frame %>% 
  bind_rows(aid.count.detail, .) %>%
  mutate(total = received + given + alone,
         received.pct = round(100 * received / (received + alone), 1))

# aid detail by fdid - focus on structure fires
aid.count.fdid <- nfirs.data$basic %>%
  mutate(INC_TYPE = as.numeric(INC_TYPE)) %>%
  filter(between(INC_TYPE, 110, 123)) %>% 
  left_join(aid.df, by="AID") %>%
  count(STATE, FDID, AID2) %>%
  ungroup %>%
  spread(AID2, n, fill=0) %>%
  mutate(sub.total = alone + received,
         total = sub.total + given,
         received.pct = round(100 * received / (sub.total), 1),
         received.pct = ifelse(sub.total==0, NA, received.pct))  %>%
  left_join(select(nfirs.data$fdheader, STATE, FDID, FD_NAME, FD_CITY)) %>%
  mutate(FD_NAME = toupper(FD_NAME))

# focus on illinois
aid.count.illinois <- aid.count.fdid %>%
  filter(STATE=="IL")

## 2: check of basic counts number of mutual aid given records
sum(nfirs.data$basic$AID %in% c(3:4)) # 253,483
nfirs.data$aid %>% nrow # 252,333

## 3: check call numbers in each set of records
mutual.aid.basic <- nfirs.data$basic %>%
  filter(AID %in% c(3:4)) %>%
  select(STATE, FDID, INC_DATE, INC_NO, EXP_NO)

mutual.aid.aid <- nfirs.data$aid %>%   
  select(STATE, FDID, INC_DATE, INC_NO, EXP_NO)

setdiff(mutual.aid.basic, mutual.aid.aid) %>% nrow # 1149
setdiff(mutual.aid.aid, mutual.aid.basic) %>% nrow  # 0 

# 4: focus on structure fires (111), mutual aid percentages
nfirs.data$basic %>%
  filter(INC_TYPE==111) %>% 
  
mutual.aid.basic %>%
  filter(duplicated(mutual.aid.basic)) %>% 
  distinct %>%
  left_join(nfirs.data$basic) %>%
  View

# quick interpretation of exposure numbers
