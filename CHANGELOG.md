## [Unreleased]

## [0.3.0] - 2025-06-04
- Fixed crash when 2D barcode contained Croatian diacritics
- Added UMCN (JMBG) parsing and generation

### Upgrade guide
- replace the `pdf-417` gem with `ruby-zint` if you are using 2D payment barcodes

## [0.2.0] - 2025-06-03
- Added 2D payment barcode generation
- Added UMCN (JMBG) validation
- Added issuer protection code generation (ZKI)
- Added Fiscalization validation QR Code generation
## [0.1.0] - 2025-05-29

- Added PIN (OIB) validation
