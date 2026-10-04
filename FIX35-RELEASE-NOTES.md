# FIX35 Release Notes — Documentation Gates & Built Showcase Validation

FIX35 integrates source documentation link validation into `script/release-verify` and validates the staged public showcase package before it can be archived. The staged validator checks package-local Markdown references, prevents path escapes, requires screenshot manifests, and requires the expected 10 synthetic screenshots. No crypto, recovery, schema, authentication, authorization, or vault-data semantics changed.
