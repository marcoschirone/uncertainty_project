# data/private — real (proprietary) inputs go here

This directory is **git-ignored** (except this README). Place the real, proprietary
Web of Science Core Collection exports here to run the actual analysis:

```
data/private/citing_jasist5.txt
data/private/323_references.txt
```

`R/config.R` prefers these over the synthetic demo files in `data/raw/`, so the
real run never modifies tracked files. Do not commit Web of Science data.
