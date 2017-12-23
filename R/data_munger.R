# 1.  initialization
Sys.setenv(JAVA_HOME='/jdk1.8.0_51')
options(java.parameters="-Xmx5g")
options(scipen=999)

ipak <- function(pkg){
    new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
    if (length(new.pkg)) 
        install.packages(new.pkg, dependencies = TRUE)
    sapply(pkg, require, character.only = TRUE)
}

ipak(c("dplyr", "rJava", "RJDBC", "ggvis"))

.jinit()

drv <- JDBC(driverClass="com.vertica.jdbc.Driver", classPath="lib/vertica-jdbc-7.1.2-0.jar")
conn <- dbConnect(drv, "jdbc:vertica://127.0.0.1:5433/defaultdb", "username", "password")

# 3. Construct Query
query <- paste("SELECT userplane_download_effective_bytes_count, userplane_download_active_millis ",
           "FROM nba.f_user_plane WHERE cal_timestamp_time BETWEEN (DATE(NOW()) - INTERVAL '1 hour') AND DATE(NOW()) AND ",
           "(userplane_download_effective_bytes_count > 0 AND userplane_download_active_millis > 0) AND rat_id = 6", sep = "")

# 4. Query
df  <- dbGetQuery(conn, query)
dbDisconnect(conn)

dim(df)

# 5. compute throughput
computThroughput <- function(volume, time)((volume * 8) / (time/1000) / 1000)
df$Throughput <- computThroughput(df$userplane_download_effective_bytes_count, df$userplane_download_active_millis)

summary(df)

# 6. create y field
q_values <- quantile(df$Throughput, probs = c(0.05, 0.95))


df$class <- df$Throughput
df$class[df$class < q_values[1]] <- 0
df$class[df$class >= q_values[1] & df$class <= q_values[2]] <- 1
df$class[df$class > q_values[2]] <- 2

head(df)
summary(df)

saveRDS(df, file = "input/user_plane.rds")
