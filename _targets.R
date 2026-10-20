# Pipeline definition. Run with targets::tar_make(); inspect with
# targets::tar_visnetwork() or targets::tar_read(<target>).

library(targets)

tar_option_set(
  packages = c("dplyr", "tidyr", "stringr", "purrr", "tibble", "ggplot2"),
  format = "rds",
  seed = 20260930
)

tar_source("R")

tables_dir <- file.path("output", "tables")
figures_dir <- file.path("output", "figures")
sensitivity_tables <- file.path(tables_dir, "revision_R1")
sensitivity_figures <- file.path(figures_dir, "revision_R1")

list(
  # Inputs ------------------------------------------------------------------
  tar_target(parts_file, input_file("wos_parts.txt"), format = "file"),
  tar_target(citing_file, input_file("wos_citing.txt"), format = "file"),
  tar_target(reference_files,
             list.files(c("data/reference", "data/corrections"), "\\.csv$", full.names = TRUE),
             format = "file"),
  tar_target(settings, analysis_settings(citing_file)),
  tar_target(ref, load_reference(reference_files)),
  tar_target(coding, read_coding("data/manual", settings), cue = tar_cue(mode = "always")),

  # Corpus and intellectual base --------------------------------------------
  tar_target(wos, read_wos(parts_file, citing_file, ref)),
  tar_target(corpus, apply_corrections(wos, ref)),
  tar_target(base, build_intellectual_base(wos$parts_refs, ref)),
  tar_target(overlap, part_overlap(wos$parts_refs, base, ref)),

  # Bibliographic coupling ---------------------------------------------------
  tar_target(coupling, couple_corpus(corpus, base, ref)),
  tar_target(described, describe_coupling(coupling, wos$parts_refs, base, ref, settings)),

  # Sensitivity analyses -----------------------------------------------------
  tar_target(inputs, analysis_inputs(corpus, coupling, base, ref, settings)),
  tar_target(corpus_records, corpus_record_list(wos, corpus, inputs$part_attr, ref)),
  tar_target(author_overlap, author_overlap_analysis(inputs, ref, settings)),
  tar_target(part_specific, part_specific_analysis(inputs, ref)),
  tar_target(temporal, temporal_analysis(inputs, settings)),
  tar_target(survivorship, survivorship_analysis(inputs, ref)),
  tar_target(venues, venue_analysis(corpus, inputs, ref)),
  tar_target(claims, claims_analysis(inputs, ref)),

  # Citation-function coding -------------------------------------------------
  tar_target(table1, table1_analysis(coding, inputs, wos, ref, settings)),
  tar_target(function_overlap, function_overlap_analysis(coding, inputs, settings)),
  tar_target(reliability, reliability_analysis(coding, settings)),

  # Reported numbers ----------------------------------------------------------
  tar_target(
    facts,
    manuscript_facts(wos, corpus, base, overlap, coupling, described, inputs, author_overlap,
                     part_specific, temporal, survivorship, venues, claims, ref, settings)
  ),
  tar_target(
    manuscript_check,
    compare_with_manuscript(facts, file.path("data", "private", "manuscript_values.csv")),
    cue = tar_cue(mode = "always")
  ),

  # Outputs -------------------------------------------------------------------
  tar_target(
    main_tables,
    write_tables(c(corpus$tables, list(corpus_records = corpus_records), base$tables,
                   overlap$tables, coupling$tables, described$tables), tables_dir),
    format = "file"
  ),
  tar_target(
    main_figures,
    write_figures(c(overlap$figures, described$figures), figures_dir),
    format = "file"
  ),
  tar_target(
    sensitivity_table_files,
    write_tables(c(author_overlap$tables, part_specific$tables, temporal$tables,
                   survivorship$tables, venues$tables, claims$tables, table1$tables,
                   function_overlap$tables, reliability$tables), sensitivity_tables),
    format = "file"
  ),
  tar_target(
    sensitivity_figure_files,
    write_figures(c(author_overlap$figures, part_specific$figures, temporal$figures,
                    survivorship$figures), sensitivity_figures),
    format = "file"
  ),
  tar_target(coding_files, write_tables(clean_coding_tables(coding), "output/coding"),
             format = "file"),
  tar_target(
    check_files,
    write_tables(list(reported_numbers = facts, manuscript_check = manuscript_check),
                 file.path("output", "checks")),
    format = "file"
  ),
  tar_target(
    published_results,
    publish_results(settings, c(main_tables, sensitivity_table_files),
                    c(main_figures, sensitivity_figure_files), run_log, facts),
    format = "file"
  ),
  tar_target(
    run_log,
    write_run_log(file.path("output", "logs", "session_info.txt"), wos, corpus, base,
                  coupling, settings),
    format = "file"
  )
)
