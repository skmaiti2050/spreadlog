# Grouped Vault documents

A scan or image-import session publishes one document, with its pages in capture/import order. Each original image retains its SHA-256. A separate document fingerprint covers the ordered list of page hashes; it excludes file locations so restoring on another device preserves it. These checks detect changes relative to stored fingerprints; they do not authenticate an instructor signature or confer regulatory certification.

The Vault shows one card and page count. Opening it provides previous/next navigation, the document fingerprint and current page fingerprint. Verification checks every original image and the ordered document fingerprint. Aircraft endorsements attach the document ID, so the attachment includes all pages. Replacement supersedes the whole group and retains all predecessor pages. Deletion removes the group and its images.

The optional logbook page field describes the first captured source page. Later scan positions are not inferred to be consecutive source logbook pages.

Database version 5 adds a nullable, versioned page manifest to the existing document row. Prior rows remain single-page documents with their existing IDs and hashes. No automatic regrouping of previously separate records is performed. Page files are written before a transactional metadata publication; failed publication removes newly written files. Backups include the manifest and every page and rewrite locations on restore.

## Verification

Automated checks cover ordered hashing, immutable inputs, serialization, one-record grouping, later-page corruption/missing images, reordered manifests, failed writes, failed replacement/publication, revision retention, deleting all pages, version-4 migration, viewer navigation, and an encrypted backup restored at a different device directory.

Device checks: capture three pages; save once; confirm one Vault card; browse all pages; attach to an aircraft; replace the document and inspect history; back up and restore on both app and web.

A separate audit against the project guidelines and archived SACAA references remains necessary. Grouping is a storage and presentation improvement, not an assertion of SACAA approval.
