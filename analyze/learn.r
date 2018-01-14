args = commandArgs(trailingOnly=T)
num_training_data <- as.integer(args[1])
period <- as.integer(args[2])
length <- 10

library(yaml)
config <- yaml.load_file("scripts/analyze/settings.yml")

library(RMySQL)
driver <- dbDriver("MySQL")
dbconnector <- dbConnect(driver, dbname="regulus", user=config$mysql$user, password=config$mysql$password, host=config$mysql$host, port=as.integer(config$mysql$port))

sql <- paste("SELECT close FROM candle_sticks WHERE pair = 'USDJPY' AND `interval` = '1-min' ORDER BY id LIMIT", num_training_data, sep=" ")
rates <- dbGetQuery(dbconnector, sql)

x <- matrix(0, nrow=(num_training_data - (period + length)), ncol=length)
y <- rep(0, num_training_data - (period + length))

for (i in 1:length(y)) {
  x[i,] <- rates$close[i : (i + length - 1)]
  y[i] <- rates$close[i + period + length - 1]
}

model = lm(y ~ x[,1] + x[,2] + x[,3] + x[,4] + x[,5] + x[,6] + x[,7] + x[,8] + x[,9] + x[,10])

timestamp <- format(Sys.time(), "%Y%m%d%H%M%S")

basename <- paste(timestamp, num_training_data, period, sep="_")
yml_filename <- paste("scripts/results/", basename, ".yml", sep="")
write("coefficients:", file=paste(yml_filename))
coefs <- as.vector(coef(model))
for (i in 2:(length+1)) {
  write(paste("  -", coefs[i]), file=yml_filename, append=T)
}
write(paste("constant:", coefs[1]), file=yml_filename, append=T)
