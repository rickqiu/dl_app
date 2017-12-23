library(plotly)

df <- readRDS("input/user_plane.rds")
df$speed <- df$userplane_download_effective_bytes_count/df$userplane_download_active_millis
df <- df[,c(1,2,5,4)]

# feature scaling
normalize <- function(x) (x/sqrt(sum(x^2)))
df$userplane_download_effective_bytes_count <- normalize(df$userplane_download_effective_bytes_count)
df$userplane_download_active_millis  <- normalize(df$userplane_download_active_millis)
df$speed <- normalize(df$speed)

df$class[df$class == 0] <- 'Low'
df$class[df$class == 1] <- 'Normal'
df$class[df$class == 2] <- 'High'
df$class <- as.factor(df$class)

plot_ly(df[1:5000,], x = ~userplane_download_effective_bytes_count,
             y = ~userplane_download_active_millis, z = ~speed, color = ~class,
         marker = list(size = 5)
        ) %>%
  add_markers() %>%
  layout(scene = list(xaxis = list(title = 'Volume'),
                     yaxis = list(title = 'Time'),
                     zaxis = list(title = 'Speed')),
         annotations = list(
           x = 1,
           y = 1,
           text = '3D Data Points',
           xref = 'paper',
           yref = 'paper',
           showarrow = FALSE
         ))
