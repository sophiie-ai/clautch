# Changelog

## [0.2.15](https://github.com/sophiie-ai/clautch/compare/v0.2.14...v0.2.15) (2026-04-01)


### Bug Fixes

* use CloudKit entitlements for re-sign step to match provisioning profile ([adbe3e6](https://github.com/sophiie-ai/clautch/commit/adbe3e64373720561564d2035c13c3fb4926cc49))

## [0.2.14](https://github.com/sophiie-ai/clautch/compare/v0.2.13...v0.2.14) (2026-04-01)


### Bug Fixes

* embed provisioning profile in CI builds for CloudKit support ([cba399d](https://github.com/sophiie-ai/clautch/commit/cba399d066f1edfca5133aeb361ab1f3b3723de7))

## [0.2.13](https://github.com/sophiie-ai/clautch/compare/v0.2.12...v0.2.13) (2026-04-01)


### Features

* add Hide When Collapsed menu option to fully hide notch panel ([08f0f5f](https://github.com/sophiie-ai/clautch/commit/08f0f5fa1f3a341dee7bade58da69705759da28e))


### Bug Fixes

* prevent CloudKit SIGTRAP crash, keep provisioning profile for iCloud ([643eeec](https://github.com/sophiie-ai/clautch/commit/643eeecc7dd4587be8ede5a8d4b04de9ee88e433))

## [0.2.12](https://github.com/sophiie-ai/clautch/compare/v0.2.11...v0.2.12) (2026-04-01)


### Bug Fixes

* remove iCloud entitlements from release signing, init CloudKit directly ([1fec81a](https://github.com/sophiie-ai/clautch/commit/1fec81a44e93fabf6f3e60cf70a61d1f42a0b6a0))

## [0.2.11](https://github.com/sophiie-ai/clautch/compare/v0.2.10...v0.2.11) (2026-03-31)


### Bug Fixes

* derive build number from version for reliable Sparkle updates ([4770986](https://github.com/sophiie-ai/clautch/commit/4770986baaea941d9cc9be0719df79a1d21e8253))

## [0.2.10](https://github.com/sophiie-ai/clautch/compare/v0.2.9...v0.2.10) (2026-03-31)


### Bug Fixes

* fetch full git history for accurate build number, fix appcast version ([679448a](https://github.com/sophiie-ai/clautch/commit/679448a9f4812e4a2ae4c61790adcac2856dac19))

## [0.2.9](https://github.com/sophiie-ai/clautch/compare/v0.2.8...v0.2.9) (2026-03-31)


### Features

* persist creature selection when reopening customization ([8e1c4b3](https://github.com/sophiie-ai/clautch/commit/8e1c4b3bbf4856df06d306a4ba5566b9aa5eae94))

## [0.2.8](https://github.com/sophiie-ai/clautch/compare/v0.2.7...v0.2.8) (2026-03-31)


### Bug Fixes

* use separate archive entitlements without iCloud for CI xcodebuild ([abb1a8d](https://github.com/sophiie-ai/clautch/commit/abb1a8d9df09efa94e49ac569988490e1c8e12e3))

## [0.2.7](https://github.com/sophiie-ai/clautch/compare/v0.2.6...v0.2.7) (2026-03-31)


### Bug Fixes

* include iCloud entitlements in release re-sign step ([2fea96d](https://github.com/sophiie-ai/clautch/commit/2fea96d82938778e0c18c02ab171429b89e70a37))

## [0.2.6](https://github.com/sophiie-ai/clautch/compare/v0.2.5...v0.2.6) (2026-03-31)


### Features

* accessories, walk sprites, dark/light mode, chat, session stats ([15c6a8c](https://github.com/sophiie-ai/clautch/commit/15c6a8cb8d993d930d88a4e68067254575ede6d9))

## [0.2.5](https://github.com/sophiie-ai/clautch/compare/v0.2.4...v0.2.5) (2026-03-31)


### Bug Fixes

* use release entitlements for CI archive (no provisioning profile needed) ([60861a6](https://github.com/sophiie-ai/clautch/commit/60861a6438e2ca7d260530daebae9594836526ab))

## [0.2.4](https://github.com/sophiie-ai/clautch/compare/v0.2.3...v0.2.4) (2026-03-31)


### Bug Fixes

* use Developer ID manual signing in CI archive step ([b14e9f4](https://github.com/sophiie-ai/clautch/commit/b14e9f4d2616c16ab8b95a9f58e1ef0cfd14a529))

## [0.2.3](https://github.com/sophiie-ai/clautch/compare/v0.2.2...v0.2.3) (2026-03-31)


### Features

* walk animation, reactions, install instructions, onboarding UX ([442f6f3](https://github.com/sophiie-ai/clautch/commit/442f6f396bcfc0b3588fbd2fd853091855a1b076))


### Bug Fixes

* fall back to HTTPS push when SSH is unavailable in release script ([5c28a69](https://github.com/sophiie-ai/clautch/commit/5c28a69fde35e98e61751c1284ec7d7074b5e8d1))
