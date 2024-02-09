options(repos = c(CRAN = "https://cran.rstudio.com/"))
install.packages("medrxivr")
install.packages("jsonlite")

library(medrxivr)
library(jsonlite)

print("Starting download data from: biorxiv")

data <- mx_api_content(
  server = 'biorxiv',
  from_date = "2000-01-01",
  to_date = "2050-01-01"
)

json_data <- toJSON(data, pretty = TRUE)

json_file_path <- "/tmp/biorxiv.json"
writeLines(json_data, json_file_path)

cat("Data exported to:", json_file_path, "\n")


# print("Starting download data from: medrxiv")

# data <- mx_api_content(
#   server = 'medrxiv',
#   from_date = "2000-01-01",
#   to_date = "2050-01-01"
# )

# json_data <- toJSON(data, pretty = TRUE)

# json_file_path <- "/tmp/medrxiv.json"
# writeLines(json_data, json_file_path)

# cat("Data exported to:", json_file_path, "\n")
