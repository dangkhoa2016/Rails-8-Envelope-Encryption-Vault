# FIX36 Release Notes — Public Package Integrity Deep Validation

FIX36 extends built public showcase validation to verify screenshot SHA256SUMS coverage/hashes, MANIFEST.tsv coverage and actual PNG width/height/bytes, plus the root package SHA256SUMS coverage and hashes for every bundled file. PNG dimensions are parsed with Python standard-library binary parsing; no image-processing dependency is added. No crypto, recovery, schema, authentication, authorization, or vault-data semantics changed.
