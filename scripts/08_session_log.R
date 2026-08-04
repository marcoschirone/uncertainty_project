up_raw <- readRDS(file.path(processed_dir, "up_raw.rds"))
cit_raw <- readRDS(file.path(processed_dir, "cit_raw.rds"))
cit_cr_corrected <- readRDS(file.path(processed_dir, "cit_cr_corrected.rds"))
up_foundations <- readRDS(file.path(processed_dir, "up_foundations.rds"))
heirs <- readRDS(file.path(processed_dir, "heirs.rds"))
surface <- readRDS(file.path(processed_dir, "surface.rds"))
record_summary <- readRDS(file.path(processed_dir, "record_correction_summary.rds"))

sink(file.path(logs_dir, "session_info.txt"))

cat("Bibliographic coupling to UP intellectual base — corrected corpus version\nDate:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n\n")

cat("UP papers:", nrow(up_raw), "| Citing (raw):", nrow(cit_raw), "| Citing (corrected):", length(unique(cit_cr_corrected$UT)), "\n")
cat("Foundations:", nrow(up_foundations), "| Heirs:", nrow(heirs), "| Surface:", nrow(surface), "\n\n")

cat("Record correction summary:\n")
print(record_summary)
cat("\n")

print(sessionInfo())
sink()

cat("Session information written to output/logs/session_info.txt\n")
