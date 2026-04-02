# Changelog

## [0.2.41](https://github.com/sophiie-ai/clautch/compare/v0.2.40...v0.2.41) (2026-04-02)


### Features

* chat bubbles, reaction animations, CloudKit subscriptions, room expiry, activity feed, and performance optimizations ([b2d2784](https://github.com/sophiie-ai/clautch/commit/b2d278437dc9dd311233f65b5e76c48a3e2e0eba))

## [0.2.40](https://github.com/sophiie-ai/clautch/compare/v0.2.39...v0.2.40) (2026-04-02)


### Features

* peer signing, day/night sky, idle variety, offline handling, tests ([9cba9d6](https://github.com/sophiie-ai/clautch/commit/9cba9d6e45813d05262b5d01d6979e880541edf4))

## [0.2.39](https://github.com/sophiie-ai/clautch/compare/v0.2.38...v0.2.39) (2026-04-02)


### Features

* usage stats window, peer tooltips, keychain tokens, and fixes ([2bca675](https://github.com/sophiie-ai/clautch/commit/2bca67554a662c0b8b002499f053f6603450b336))

## [0.2.38](https://github.com/sophiie-ai/clautch/compare/v0.2.37...v0.2.38) (2026-04-02)


### Features

* sync creature positions across room peers via CloudKit ([93a6833](https://github.com/sophiie-ai/clautch/commit/93a6833b8df0137d2db7c971b6596a4cc44571f8))

## [0.2.37](https://github.com/sophiie-ai/clautch/compare/v0.2.36...v0.2.37) (2026-04-02)


### Features

* CloudKit retry logic with backoff, batch cleanup, and new tests ([88f0a1f](https://github.com/sophiie-ai/clautch/commit/88f0a1f93ce0b39092af17327736cb8cd905c466))
* harden CloudKit rooms — conditional writes, input validation, stronger codes ([0576973](https://github.com/sophiie-ai/clautch/commit/0576973e015851553e1b62b92e37e416a516f76b))


### Performance

* reduce CPU usage when panel is collapsed ([d6e2a21](https://github.com/sophiie-ai/clautch/commit/d6e2a2149086b783cf309b4ff855752714f6f7d7))

## [0.2.36](https://github.com/sophiie-ai/clautch/compare/v0.2.35...v0.2.36) (2026-04-02)


### Bug Fixes

* return to accessory mode on resign active, not window close ([3844c14](https://github.com/sophiie-ai/clautch/commit/3844c14f49ecde26bb63651abf5eb5cfa7585bc3))
* stop Sparkle update check from repeatedly stealing focus ([71e7fd8](https://github.com/sophiie-ai/clautch/commit/71e7fd8812eeb3d76d50bf7e9eb1272b93780c60))

## [0.2.35](https://github.com/sophiie-ai/clautch/compare/v0.2.34...v0.2.35) (2026-04-02)


### Features

* switch Sparkle updates to ZIP and auto-eject stale DMG volumes ([a04d609](https://github.com/sophiie-ai/clautch/commit/a04d6096cab45d75dcdd6099d4200020d1466138))

## [0.2.34](https://github.com/sophiie-ai/clautch/compare/v0.2.33...v0.2.34) (2026-04-01)


### Features

* rework expanded panel layout for consistent proportions ([760fd9e](https://github.com/sophiie-ai/clautch/commit/760fd9efc0712118c4a70281a8d91f85aac9b658))


### Bug Fixes

* refine expanded panel overlay styles ([4e772b2](https://github.com/sophiie-ai/clautch/commit/4e772b20f22ac45e2cc5a53dd4fd926fff72e5ba))
* use 2px top padding on event log overlay ([7b0cc45](https://github.com/sophiie-ai/clautch/commit/7b0cc45e6739b347af886e598d4a78979e6b61f6))

## [0.2.33](https://github.com/sophiie-ai/clautch/compare/v0.2.32...v0.2.33) (2026-04-01)


### Features

* transparent collapsed, consistent grass, week usage in status bar ([e5315dd](https://github.com/sophiie-ai/clautch/commit/e5315ddace5f1398c388a50f44d0318285588262))

## [0.2.32](https://github.com/sophiie-ai/clautch/compare/v0.2.31...v0.2.32) (2026-04-01)


### Bug Fixes

* collapsed cleanup, thinner grass, better padding, status bar visibility ([f7dad0e](https://github.com/sophiie-ai/clautch/commit/f7dad0e9b9c3c3610a60f1f6406164e85dec94df))

## [0.2.31](https://github.com/sophiie-ai/clautch/compare/v0.2.30...v0.2.31) (2026-04-01)


### Bug Fixes

* prevent crash when event log disabled (invalid star range) ([a010d1c](https://github.com/sophiie-ai/clautch/commit/a010d1c9230a7fcc11282e30c44a3ad8e4a5f54a))

## [0.2.30](https://github.com/sophiie-ai/clautch/compare/v0.2.29...v0.2.30) (2026-04-01)


### Bug Fixes

* smaller panel when event log disabled, better content padding ([e50b2ce](https://github.com/sophiie-ai/clautch/commit/e50b2cec8caae48ede81cb5361cba8ff472776fc))

## [0.2.29](https://github.com/sophiie-ai/clautch/compare/v0.2.28...v0.2.29) (2026-04-01)


### Bug Fixes

* clip all content to panel shape, event log stays inside bounds ([a804811](https://github.com/sophiie-ai/clautch/commit/a8048111fc1642ffbc32907d971eade88af36a24))

## [0.2.28](https://github.com/sophiie-ai/clautch/compare/v0.2.27...v0.2.28) (2026-04-01)


### Bug Fixes

* decode Claude Code's actual hook format (hook_event_name + tool_response) ([fe414dd](https://github.com/sophiie-ai/clautch/commit/fe414dda1cc69f131a03b5f6d8d5902034997d73))
* panel extends to screen top, fix event log overflow, wider panel ([eb5e384](https://github.com/sophiie-ai/clautch/commit/eb5e3846be2e552bb57fd04a1e3108e279317dd2))

## [0.2.27](https://github.com/sophiie-ai/clautch/compare/v0.2.26...v0.2.27) (2026-04-01)


### Features

* scenic panel redesign with sky, event log, and status bar ([f31ed36](https://github.com/sophiie-ai/clautch/commit/f31ed362111af0458f5ddbd72a1773ae8eeb74fc))

## [0.2.26](https://github.com/sophiie-ai/clautch/compare/v0.2.25...v0.2.26) (2026-04-01)


### Features

* sentiment analysis with 7 emotion states driven by event patterns ([2bdd918](https://github.com/sophiie-ai/clautch/commit/2bdd9188d775c07cba95ff4e129a63e2b09e12f9))

## [0.2.25](https://github.com/sophiie-ai/clautch/compare/v0.2.24...v0.2.25) (2026-04-01)


### Features

* unit tests, friendly errors, creature blinks, ghost cleanup ([af89f87](https://github.com/sophiie-ai/clautch/commit/af89f872a728378dab26140c0f47e3a48e7d260d))

## [0.2.24](https://github.com/sophiie-ai/clautch/compare/v0.2.23...v0.2.24) (2026-04-01)


### Bug Fixes

* set CFBundleVersion in Info.plist before build, force Sparkle windows to front ([b223e81](https://github.com/sophiie-ai/clautch/commit/b223e811c89cc1df03a88e2627f5ec59778ee319))

## [0.2.23](https://github.com/sophiie-ai/clautch/compare/v0.2.22...v0.2.23) (2026-04-01)


### Bug Fixes

* keep Sparkle update windows in front throughout entire flow ([768bbc5](https://github.com/sophiie-ai/clautch/commit/768bbc52977eb2bebd3cf275dafaa886107a6ccf))

## [0.2.22](https://github.com/sophiie-ai/clautch/compare/v0.2.21...v0.2.22) (2026-04-01)


### Features

* reaction notifications, activity feed, multi-display support ([d641f76](https://github.com/sophiie-ai/clautch/commit/d641f768338f2cd663d04c196ebce6a123954d99))

## [0.2.21](https://github.com/sophiie-ai/clautch/compare/v0.2.20...v0.2.21) (2026-04-01)


### Features

* pause mode to stop all processing, hide notch items on non-notch Macs ([4de76e2](https://github.com/sophiie-ai/clautch/commit/4de76e27e061f95017b0ce2804acbdf8a4455eef))

## [0.2.20](https://github.com/sophiie-ai/clautch/compare/v0.2.19...v0.2.20) (2026-04-01)


### Bug Fixes

* bring Check for Updates window to front ([7fd378e](https://github.com/sophiie-ai/clautch/commit/7fd378e8fd258901475491ddf4b0a6720778f009))

## [0.2.19](https://github.com/sophiie-ai/clautch/compare/v0.2.18...v0.2.19) (2026-04-01)


### Bug Fixes

* stable creature positioning with overlay-based chat and reactions ([11723e4](https://github.com/sophiie-ai/clautch/commit/11723e4091129cf64002aa7cda7edb4d5710bbbf))

## [0.2.18](https://github.com/sophiie-ai/clautch/compare/v0.2.17...v0.2.18) (2026-04-01)


### Features

* pixel art reactions instead of emoji overlays ([6234c3c](https://github.com/sophiie-ai/clautch/commit/6234c3c3f1e79027cbac0821e12ed5ed290ca5ea))

## [0.2.17](https://github.com/sophiie-ai/clautch/compare/v0.2.16...v0.2.17) (2026-04-01)


### Bug Fixes

* initialize localState on room join and before sending reactions/chat ([16398b9](https://github.com/sophiie-ai/clautch/commit/16398b9626453e64cca94e03b19444dbfd0d43ea))

## [0.2.16](https://github.com/sophiie-ai/clautch/compare/v0.2.15...v0.2.16) (2026-04-01)


### Bug Fixes

* add application-identifier and team-identifier to CloudKit entitlements ([63e610f](https://github.com/sophiie-ai/clautch/commit/63e610f0abed82c4f3f1d692046e8db83afd8cc3))

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
