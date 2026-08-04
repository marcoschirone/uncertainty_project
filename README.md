# UP Bibliographic-Coupling Project

## Reconstructing the Intellectual Base of the Uncertainty Project

> **Data notice.** This repository contains synthetic demonstration data rather than Web of Science Core Collection records. The workflow is fully executable, but the resulting statistics, tables, and figures are illustrative and do not reproduce the published results.

---

## Overview

This repository provides a reproducible R workflow for reconstructing and analysing the intellectual base of the Uncertainty Project through bibliographic coupling.

The workflow demonstrates:

- citation parsing
- corpus validation
- correction-layer processing
- intellectual-base reconstruction
- bibliographic coupling
- temporal analysis
- figure generation

without redistributing proprietary Clarivate Web of Science data.

---

## Input Files

### `citing_jasist5.txt`

Synthetic Web of Science–style export representing the five Uncertainty Project source articles and their cited references.

### Synthetic Citing Corpus

The repository also includes a synthetic citing-record export.

---

## Running the Analysis

```r
source("scripts/00_run_all.R")
```

## Reproducibility Statement

This repository reproduces the analytical workflow but not the published numerical results.

Published results require licensed Web of Science data that cannot be redistributed.

## License

Code is distributed under the MIT License.
