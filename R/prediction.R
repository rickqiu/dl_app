options(scipen=999)
library(mlbench)
library(caret)
library(h2o)

h2o.init(nthreads=4, min_mem_size="5g", max_mem_size="10g")
h2o.removeAll()

X_test <- readRDS("R/test_data.rds")
test_h2o <- as.h2o(X_test)
model <- h2o.loadModel("dl_grid_random_model_0")
#model

pred = h2o.predict(model,test_h2o)
pred <- as.data.frame(pred)

cm <- caret::confusionMatrix(pred$predict, X_test[,4])
cm
cm$byClass[7]

