# Vault Search — accuracy and performance

> 🌐 Language / Ngôn ngữ: **English** | [Tiếng Việt](VAULT-SEARCH-PERFORMANCE.vi.md)

## What changed

The earlier release searched only the 250 most recently/favorited candidates, so a matching encrypted title/tag outside that window could be missed. The new source removes this arbitrary cap. Searches remain **scoped to the signed-in owner**.

Without a private title/tag search, PostgreSQL now counts and paginates metadata **before decryption**. The default six-item page decrypts at most six items. Tag entry is now free text with suggestions from the current page; tags on other pages can still be searched.

## Performance boundary

Searching an encrypted title or tag still decrypts every matching metadata candidate: O(N). For AWS KMS each DEK unwrap generally makes a KMS decrypt request, so full encrypted searches can become slow and costly. No plaintext title/tag index is persisted. There is no AWS KMS latency or billing benchmark in this release.

A future HMAC blind index would need a separate threat model, index-key custody, normalization, migrations and rotation plan.

## Synthetic local benchmark

On a disposable PostgreSQL test DB and synthetic LocalFile KEK, run:

    RAILS_ENV=test VAULT_KEY_PROVIDER=local_file VAULT_BENCH_ITEMS=260 bin/rails runner script/benchmark-vault-search

The script creates synthetic items in a transaction, measures create/list/title/tag time and rolls back. Record the CPU, Ruby, PostgreSQL versions and repeat several times for meaningful comparisons. Automated tests also assert page-bounded decryption and matching beyond the previous 250-item boundary.

**This is not an AWS KMS benchmark.** Do not run it with production data or keys.
