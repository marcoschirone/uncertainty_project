source("R/config.R")
source("R/packages.R")
source("R/utils.R")
source("R/lookups.R")
source("R/corrections.R")

if (!file.exists(up_file)) stop("Missing source file: ", up_file, call. = FALSE)
if (!file.exists(cit_file)) stop("Missing citing file: ", cit_file, call. = FALSE)
