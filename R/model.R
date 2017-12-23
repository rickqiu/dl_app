options(scipen=999)
library(mlbench)
library(caret)
library(h2o)

h2o.init(nthreads=4, min_mem_size="5g", max_mem_size="10g")
h2o.removeAll()

# read in data
df <- readRDS("input/user_plane.rds")
df$speed <- df$userplane_download_effective_bytes_count/df$userplane_download_active_millis
df <- df[,c(1,2,5,4)]

# data summary
dim(df)
head(df)
summary(df)
table(df$class)

# feature scaling
normalize <- function(x) (x/sqrt(sum(x^2)))
df$userplane_download_effective_bytes_count <- normalize(df$userplane_download_effective_bytes_count)
df$userplane_download_active_millis  <- normalize(df$userplane_download_active_millis)
df$speed <- normalize(df$speed)

# partition data train:validation:test 60:20:20
df$class <-  as.factor(df[,4])

idx <- createDataPartition(df$class, p = .6, list = FALSE)
X_train <- df[idx,]

remaining <- df[-idx,]
idx1 <- createDataPartition(remaining$class, p = .5, list = FALSE)
X_val <- remaining[idx1,]
X_test <- remaining[-idx1,]
saveRDS(X_test, file ="input/test_data.rds")

train_h2o <- as.h2o(X_train)
val_h2o <- as.h2o(X_val)
test_h2o <- as.h2o(X_test)

# Define list of hyperparameters
hyper_params <- list(
  activation=c("Rectifier","Tanh","Maxout","RectifierWithDropout","TanhWithDropout","MaxoutWithDropout"),
  hidden=list(c(64,64,32,32,32), c(32,32,32,32,32,32)),
  input_dropout_ratio=c(0,0.05),
  l1=seq(0,1e-4,1e-6),
  l2=seq(0,1e-4,1e-6)
)

search_criteria <- list(strategy = "RandomDiscrete", 
                       max_runtime_secs = 600, 
                       max_models = 100, 
                       seed=1234567, 
                       stopping_rounds=5, 
                       stopping_tolerance=1e-2,  
                       stopping_metric="logloss")

# grid search for the best model
dl_random_grid <- h2o.grid(
  algorithm="deeplearning",
  grid_id = "dl_grid_random",
  training_frame=train_h2o,
  validation_frame=val_h2o, 
  x = c(1,2,3),
  y=4,
  epochs=100,
  score_validation_samples=10000, 
  score_duty_cycle=0.025,         
  max_w2=10, 
  hyper_params = hyper_params,
  search_criteria = search_criteria
) 

grid <- h2o.getGrid("dl_grid_random",sort_by="logloss",decreasing=FALSE)
best_model <- h2o.getModel(grid@model_ids[[1]])
best_model

# save the best model and test data
#h2o.saveModel(best_model, path=getwd(), force=TRUE)
#saveRDS(X_test, file="input/test_data.rds")
