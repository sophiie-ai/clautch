# Changelog

## [0.19.1](https://github.com/sophiie-ai/clautch/compare/v0.19.0...v0.19.1) (2026-04-09)


### Bug Fixes

* separate collapsed emotion and chat into distinct positions ([fb98b9a](https://github.com/sophiie-ai/clautch/commit/fb98b9aedb659b1a6e4df46e1397c3fe722d950c))

## [0.19.0](https://github.com/sophiie-ai/clautch/compare/v0.18.2...v0.19.0) (2026-04-09)


### Features

* move collapsed chat bubbles beside creatures with emotions ([d4f4b69](https://github.com/sophiie-ai/clautch/commit/d4f4b697f3e45bea0ecb9768f4770023ded68eb3))
* show chat messages above collapsed creatures ([9ce5bbf](https://github.com/sophiie-ai/clautch/commit/9ce5bbfe346fbfdd43dea61b570f8d36f0ac80e6))
* show emotion indicators beside collapsed creatures ([ae75f3a](https://github.com/sophiie-ai/clautch/commit/ae75f3afd88bdedcabac9f03afd261f869e961f5))

## [0.18.2](https://github.com/sophiie-ai/clautch/compare/v0.18.1...v0.18.2) (2026-04-08)


### Bug Fixes

* broadcast chat, reactions, and interactions immediately ([c3438df](https://github.com/sophiie-ai/clautch/commit/c3438df624fd054eaeae0d431e422aa742aab0aa))

## [0.18.1](https://github.com/sophiie-ai/clautch/compare/v0.18.0...v0.18.1) (2026-04-07)


### Bug Fixes

* show SettingsView in SwiftUI Settings scene instead of EmptyView ([d4c2556](https://github.com/sophiie-ai/clautch/commit/d4c2556eb928a001d1eb9b9fcb9739c6a443c43a))

## [0.18.0](https://github.com/sophiie-ai/clautch/compare/v0.17.5...v0.18.0) (2026-04-07)


### Features

* user status + custom scene backgrounds ([#79](https://github.com/sophiie-ai/clautch/issues/79)) ([82fa0db](https://github.com/sophiie-ai/clautch/commit/82fa0db400ba1d49118ce8fa71e1c82fdde409b1))

## [0.17.5](https://github.com/sophiie-ai/clautch/compare/v0.17.4...v0.17.5) (2026-04-07)


### Bug Fixes

* add pull-requests write permission to release workflow ([1d0306a](https://github.com/sophiie-ai/clautch/commit/1d0306a4358b27a50dd9ea734c760153fd00e852))
* crash when leaving room due to ForEach index race ([7c72279](https://github.com/sophiie-ai/clautch/commit/7c72279bc7fddf147b5a7b3ae75bb2b83477c782))

## [0.17.4](https://github.com/sophiie-ai/clautch/compare/v0.17.3...v0.17.4) (2026-04-07)


### Bug Fixes

* open PR for appcast update instead of pushing directly to main ([a66f44e](https://github.com/sophiie-ai/clautch/commit/a66f44e83977671f92f26c9ab1a4bd7b811b63ae))

## [0.17.3](https://github.com/sophiie-ai/clautch/compare/v0.17.2...v0.17.3) (2026-04-07)


### Bug Fixes

* use admin PAT for appcast push to bypass branch protection ([8b3c9ee](https://github.com/sophiie-ai/clautch/commit/8b3c9ee72d9c23607aa0512eaa6460d2c46cafe2))

## [0.17.2](https://github.com/sophiie-ai/clautch/compare/v0.17.1...v0.17.2) (2026-04-07)


### Bug Fixes

* pass clicks through below panel when event log is disabled ([7462105](https://github.com/sophiie-ai/clautch/commit/746210523b6f6cc1c5d8fa11a46b4ddcb240a178))
* sync release-please manifest to v0.17.1 after manual releases ([a644836](https://github.com/sophiie-ai/clautch/commit/a644836c4a66b80e81959a74adad8170294c74e2))

## [0.17.1](https://github.com/sophiie-ai/clautch/compare/v0.17.0...v0.17.1) (2026-04-07)


### Bug Fixes

* ensure room presence is deleted before process exits on quit ([2d52c5d](https://github.com/sophiie-ai/clautch/commit/2d52c5dcc09406f9c0b010a01c9284c8b40317e9))

## [0.17.0](https://github.com/sophiie-ai/clautch/compare/v0.16.0...v0.17.0) (2026-04-07)


### Features

* redesign room chat with iMessage-style bubbles and compact peer avatars ([e6a9e4b](https://github.com/sophiie-ai/clautch/commit/e6a9e4b984cb8cfeb1bc9bd926330fe4e0e8475a))


### Bug Fixes

* ensure room presence is deleted before process exits on quit ([2d52c5d](https://github.com/sophiie-ai/clautch/commit/2d52c5dcc09406f9c0b010a01c9284c8b40317e9))

## [0.16.0](https://github.com/sophiie-ai/clautch/compare/v0.15.0...v0.16.0) (2026-04-06)


### Features

* accessories, walk sprites, dark/light mode, chat, session stats ([15c6a8c](https://github.com/sophiie-ai/clautch/commit/15c6a8cb8d993d930d88a4e68067254575ede6d9))
* add 5 new creature features — accessories, seasons, mood journal, interactions, sharing ([f413582](https://github.com/sophiie-ai/clautch/commit/f413582531b3895f2b30eb4237eaf17ea3a27583))
* add gamification system with streaks, achievements, and creature evolution ([300d615](https://github.com/sophiie-ai/clautch/commit/300d6159ca93f2e013e331a167cebe5919423bc1))
* add Hide When Collapsed menu option to fully hide notch panel ([08f0f5f](https://github.com/sophiie-ai/clautch/commit/08f0f5fa1f3a341dee7bade58da69705759da28e))
* add initial project structure for Clautch, a macOS notch companion app ([7ed8f8d](https://github.com/sophiie-ai/clautch/commit/7ed8f8de8b0057ce5764e9e9b02ce0e97aa61510))
* add prestige system, weekly challenges, and exponential XP curve ([c749905](https://github.com/sophiie-ai/clautch/commit/c7499052b18706b0fa7a9249a81ac76ae42cfacb))
* add screenshot of creature in notch to landing page ([b7a4690](https://github.com/sophiie-ai/clautch/commit/b7a469004b740409d416354f01284724934edcc0))
* add Vercel Web Analytics to landing page ([3ba4cf0](https://github.com/sophiie-ai/clautch/commit/3ba4cf0299c79ec48b42584aa8bf7e339c5981ed))
* app icon, README, DMG build, pure bash hooks, session details, creature facing, Sparkle updates ([6d9d44e](https://github.com/sophiie-ai/clautch/commit/6d9d44e79c2c105276e9b4a721293692ef4b25b7))
* bug fixes, UX improvements, and updated build scripts ([aeb5d4e](https://github.com/sophiie-ai/clautch/commit/aeb5d4efec82a1c805d638abfc9118c686ea7dc3))
* changelog page, pipeline diagram, overlay extraction, notification protocol, and 14 new tests ([a65d9b4](https://github.com/sophiie-ai/clautch/commit/a65d9b46fa47dde78f0cb198516a3a4587a5a2a6))
* chat bubbles, reaction animations, CloudKit subscriptions, room expiry, activity feed, and performance optimizations ([b2d2784](https://github.com/sophiie-ai/clautch/commit/b2d278437dc9dd311233f65b5e76c48a3e2e0eba))
* click peer creature to wave, and animated onboarding-to-notch transition ([22baf1c](https://github.com/sophiie-ai/clautch/commit/22baf1cf7ed75763544c25dd1590c28fc7694fef))
* click-to-toggle notch panel with sound effects ([19c1f8e](https://github.com/sophiie-ai/clautch/commit/19c1f8ed7d213714fed863c5e68ee482d11fa7b1))
* CloudKit retry logic with backoff, batch cleanup, and new tests ([88f0a1f](https://github.com/sophiie-ai/clautch/commit/88f0a1f93ce0b39092af17327736cb8cd905c466))
* code cleanup, file extraction, smooth transitions, and chat persistence ([c1173b4](https://github.com/sophiie-ai/clautch/commit/c1173b449a7016cf95d16affd6f689ba3065305b))
* creature state effects and automatic hook repair ([093bb0a](https://github.com/sophiie-ai/clautch/commit/093bb0a43846d252463221e7ffa145270291fbdc))
* custom pixel ghost menu bar icon + updated landing page ([521f61f](https://github.com/sophiie-ai/clautch/commit/521f61f6e9030340fcd2f12e1db4bbb6591a0eea))
* deep links, CloudKit protocol, notification grouping, menubar creature, sky interpolation, typing indicator, creature settings, walk paths, menu reorg, and tests ([04d68fd](https://github.com/sophiie-ai/clautch/commit/04d68fdec23112483907250ce0dc9a851c434032))
* deepen gamification — XP scaling, 11 new achievements, daily quests, 6 evolution stages ([1fb9e0f](https://github.com/sophiie-ai/clautch/commit/1fb9e0f4820803cf275818780da015c4b7f1dd46))
* display picker in Settings for choosing which screen shows the notch panel ([57c0b54](https://github.com/sophiie-ai/clautch/commit/57c0b549a07ab58fe00882592b84fe5cd3aa40ed))
* Dynamic Island style notch panel with hover expand and creature wandering ([83ae276](https://github.com/sophiie-ai/clautch/commit/83ae2760c5064b5d7604a7b0003b9e5dd41e1a96))
* enable CloudKit with iCloud container entitlement ([549adef](https://github.com/sophiie-ai/clautch/commit/549adef0d99ed19f8908710d6be05e05e6443b46))
* expanded panel info, emotions, click-outside-collapse, onboarding fix ([6967329](https://github.com/sophiie-ai/clautch/commit/6967329278c55426c861f2c2a90c2d4e0455f927))
* extract CreatureIslandOverlay and add smooth state transition animation ([bc8386c](https://github.com/sophiie-ai/clautch/commit/bc8386cfe3c207966556c513395c1d9ebe2e8d10))
* fix daily quest counters, lock indicators in onboarding, creature pet interaction ([1548f0a](https://github.com/sophiie-ai/clautch/commit/1548f0a99c1ad15f43c948a68443270cc67a5237))
* harden CloudKit rooms — conditional writes, input validation, stronger codes ([0576973](https://github.com/sophiie-ai/clautch/commit/0576973e015851553e1b62b92e37e416a516f76b))
* interactive notch simulation with 3 creatures, wandering, and reactions ([d398cea](https://github.com/sophiie-ai/clautch/commit/d398cea9f2a757031e754c8b7d1f7661439b587c))
* keychain confirmation dialog and README update ([87e1759](https://github.com/sophiie-ai/clautch/commit/87e1759959f6b99b20dac5fadc42f142765ae2cd))
* menubar session summary, notifications, and launch at login ([7643ad5](https://github.com/sophiie-ai/clautch/commit/7643ad5e9651a9d4bcdb63632d84864007b32cc7))
* needs-input indicator when session awaits human response ([1823b54](https://github.com/sophiie-ai/clautch/commit/1823b54032895da988b39605d0e0dda7d9487132))
* pause mode to stop all processing, hide notch items on non-notch Macs ([4de76e2](https://github.com/sophiie-ai/clautch/commit/4de76e27e061f95017b0ce2804acbdf8a4455eef))
* peer signing, day/night sky, idle variety, offline handling, tests ([9cba9d6](https://github.com/sophiie-ai/clautch/commit/9cba9d6e45813d05262b5d01d6979e880541edf4))
* permission indicator, creature personalities, layout refactor, contrast fix, and pipeline tests ([c8bc0ea](https://github.com/sophiie-ai/clautch/commit/c8bc0ea257e2e97165ea01b731390168ecaf87e8))
* persist creature selection when reopening customization ([8e1c4b3](https://github.com/sophiie-ai/clautch/commit/8e1c4b3bbf4856df06d306a4ba5566b9aa5eae94))
* pixel art reactions instead of emoji overlays ([6234c3c](https://github.com/sophiie-ai/clautch/commit/6234c3c3f1e79027cbac0821e12ed5ed290ca5ea))
* polished onboarding fly-to-notch animation, creatures beside notch when collapsed ([3fcda20](https://github.com/sophiie-ai/clautch/commit/3fcda2023658e549c67638e133c96568a4d0f2f7))
* random micro-animations when collapsed (hop and tilt) ([aa14eb5](https://github.com/sophiie-ai/clautch/commit/aa14eb5fb8b2f2afb8e6e46a9c0ae7aa728d9015))
* reaction notifications, activity feed, multi-display support ([d641f76](https://github.com/sophiie-ai/clautch/commit/d641f768338f2cd663d04c196ebce6a123954d99))
* redesign landing page with animations, SEO, and responsive layout ([e123b8f](https://github.com/sophiie-ai/clautch/commit/e123b8ff272536adcbf5e07508a8e61caa14cae2))
* render attention indicators as pixel art inside creature canvas ([5e79133](https://github.com/sophiie-ai/clautch/commit/5e791337de202f5baedc5521d93f2e26f07bb488))
* replace screenshot with animated canvas notch simulation ([acba370](https://github.com/sophiie-ai/clautch/commit/acba37082c546ca596b91c623c8b54fba19e6504))
* rework expanded panel layout for consistent proportions ([760fd9e](https://github.com/sophiie-ai/clautch/commit/760fd9efc0712118c4a70281a8d91f85aac9b658))
* scenic panel redesign with sky, event log, and status bar ([f31ed36](https://github.com/sophiie-ai/clautch/commit/f31ed362111af0458f5ddbd72a1773ae8eeb74fc))
* sentiment analysis with 7 emotion states driven by event patterns ([2bdd918](https://github.com/sophiie-ai/clautch/commit/2bdd9188d775c07cba95ff4e129a63e2b09e12f9))
* settings window, accessibility labels, window conventions, and spacing fixes ([74312a0](https://github.com/sophiie-ai/clautch/commit/74312a03a9102c8accd4cab5fb93acd10e979fc9))
* stepped onboarding flow with skip button, and creature hover bounce ([91dfab1](https://github.com/sophiie-ai/clautch/commit/91dfab1b15ca9ebb24b3a26c7401d9dfa12d8b4e))
* styled DMG installer with create-dmg, updated release v0.1.2 ([c16b3ca](https://github.com/sophiie-ai/clautch/commit/c16b3ca351eecb010d0782dbba645809bce68fb5))
* support non-notch Macs with virtual top-center panel ([d963e85](https://github.com/sophiie-ai/clautch/commit/d963e85eb1bb8e2a2caec220ceaf413a1c401615))
* switch Sparkle updates to ZIP and auto-eject stale DMG volumes ([a04d609](https://github.com/sophiie-ai/clautch/commit/a04d6096cab45d75dcdd6099d4200020d1466138))
* sync creature positions across room peers via CloudKit ([93a6833](https://github.com/sophiie-ai/clautch/commit/93a6833b8df0137d2db7c971b6596a4cc44571f8))
* transparent collapsed, consistent grass, week usage in status bar ([e5315dd](https://github.com/sophiie-ai/clautch/commit/e5315ddace5f1398c388a50f44d0318285588262))
* unit tests, friendly errors, creature blinks, ghost cleanup ([af89f87](https://github.com/sophiie-ai/clautch/commit/af89f872a728378dab26140c0f47e3a48e7d260d))
* usage stats window, peer tooltips, keychain tokens, and fixes ([2bca675](https://github.com/sophiie-ai/clautch/commit/2bca67554a662c0b8b002499f053f6603450b336))
* Vercel appcast hosting, Developer ID signing, Sparkle EdDSA key, release script ([7128b0c](https://github.com/sophiie-ai/clautch/commit/7128b0cba581ca4ffadd2b041d890e50890f34f7))
* walk animation, reactions, install instructions, onboarding UX ([442f6f3](https://github.com/sophiie-ai/clautch/commit/442f6f396bcfc0b3588fbd2fd853091855a1b076))
* walk easing, mood sparkline, sound effects, WindowCoordinator, mock tests, and Swift 6 concurrency ([e125062](https://github.com/sophiie-ai/clautch/commit/e1250624c2a5f3a302b91bab8e9e3ce3dda80b35))


### Bug Fixes

* add application-identifier and team-identifier to CloudKit entitlements ([63e610f](https://github.com/sophiie-ai/clautch/commit/63e610f0abed82c4f3f1d692046e8db83afd8cc3))
* add CloudKit entitlements to release build ([e26e9c6](https://github.com/sophiie-ai/clautch/commit/e26e9c61dbd3ceabfbb4208cc9c79a3558a9e85b))
* add favicon and apple-touch-icon to website ([e5f8546](https://github.com/sophiie-ai/clautch/commit/e5f8546b249cd1ff527cc091d681f69327efb4c8))
* add sitemap.xml, robots.txt, and canonical tags for SEO ([2ee9c56](https://github.com/sophiie-ai/clautch/commit/2ee9c569ce6a84e462d2b1714d9c94744423ec6d))
* all windows now center on first show and come to front reliably ([a6a55ec](https://github.com/sophiie-ai/clautch/commit/a6a55ecbc01d014d880cc8fd7b03b855273dea79))
* app icon now compiles into the built app ([57ff0e2](https://github.com/sophiie-ai/clautch/commit/57ff0e27d5dc06fbd66c538e8f38e2b31e9b4b48))
* archive with automatic signing for CloudKit provisioning profile ([33d82c0](https://github.com/sophiie-ai/clautch/commit/33d82c07bb5c1873adb2c42ff3741012241d9891))
* bring Check for Updates window to front ([7fd378e](https://github.com/sophiie-ai/clautch/commit/7fd378e8fd258901475491ddf4b0a6720778f009))
* changing creature no longer causes app to quit ([2b4ac91](https://github.com/sophiie-ai/clautch/commit/2b4ac91e8c3f9f7ab5c3c1b000d26bf64c06e81c))
* changing creature no longer quits app ([899c4e0](https://github.com/sophiie-ai/clautch/commit/899c4e04c332590a8b92fe565e55e26545ca01e0))
* clip all content to panel shape, event log stays inside bounds ([a804811](https://github.com/sophiie-ai/clautch/commit/a8048111fc1642ffbc32907d971eade88af36a24))
* collapsed cleanup, thinner grass, better padding, status bar visibility ([f7dad0e](https://github.com/sophiie-ai/clautch/commit/f7dad0e9b9c3c3610a60f1f6406164e85dec94df))
* collapsed clip shape uses correct y origin (top of view, not bottom) ([a3663b9](https://github.com/sophiie-ai/clautch/commit/a3663b980709902ff62e13412b789f53869da5b3))
* collapsed panel only intercepts clicks in notch/menubar strip ([86df880](https://github.com/sophiie-ai/clautch/commit/86df880f9bec015b6da0b14e983a1174c8553c6b))
* collapsed widget clips to notch height and lowers window level ([534d0ea](https://github.com/sophiie-ai/clautch/commit/534d0ea8ec6b3db8a3e5247bf680d7c365e4dbbf))
* collapsed widget stays within menu bar height, no peek below ([7d5bfae](https://github.com/sophiie-ai/clautch/commit/7d5bfaef6c3b1207ea8c64adbb12e2557766dae8))
* decode Claude Code's actual hook format (hook_event_name + tool_response) ([fe414dd](https://github.com/sophiie-ai/clautch/commit/fe414dda1cc69f131a03b5f6d8d5902034997d73))
* derive build number from version for reliable Sparkle updates ([4770986](https://github.com/sophiie-ai/clautch/commit/4770986baaea941d9cc9be0719df79a1d21e8253))
* display picker in Settings now properly recreates panel on selected screen ([1f75683](https://github.com/sophiie-ai/clautch/commit/1f756836f24c219d0ae158989c445138e30e8714))
* dynamic version in menu, windows appear in front, styled DMG installer ([6b07a87](https://github.com/sophiie-ai/clautch/commit/6b07a87693bbd9c6b798ad94c43849b96e5ba8be))
* embed provisioning profile in CI builds for CloudKit support ([cba399d](https://github.com/sophiie-ai/clautch/commit/cba399d066f1edfca5133aeb361ab1f3b3723de7))
* expanded panel only intercepts clicks within visible island bounds ([f5bba52](https://github.com/sophiie-ai/clautch/commit/f5bba52489b82259ec9eefc706a739121e8b6bb4))
* fall back to HTTPS push when SSH is unavailable in release script ([5c28a69](https://github.com/sophiie-ai/clautch/commit/5c28a69fde35e98e61751c1284ec7d7074b5e8d1))
* fetch full git history for accurate build number, fix appcast version ([679448a](https://github.com/sophiie-ai/clautch/commit/679448a9f4812e4a2ae4c61790adcac2856dac19))
* find notch on any screen, not just NSScreen.main ([5d3f0f8](https://github.com/sophiie-ai/clautch/commit/5d3f0f82130e7a43611834d1b4af87bd0ccaddeb))
* fit landing page in single viewport on desktop ([22e19d5](https://github.com/sophiie-ai/clautch/commit/22e19d5065d33817cd68a218f420282ebd23c5e6))
* guard mock CloudKit tests for missing UserProfile on CI ([a7ac95c](https://github.com/sophiie-ai/clautch/commit/a7ac95c847de8f2416dfcbb95ed4beef51a36881))
* hide .background and .fseventsd in DMG with chflags hidden ([2cb9200](https://github.com/sophiie-ai/clautch/commit/2cb9200c6cca05348c77548446273662eb68f80f))
* hide notch panel during Mission Control and Expose ([ac31d01](https://github.com/sophiie-ai/clautch/commit/ac31d015d36d0a02d6328e4eaf35658a17381f91))
* improve accessibility score — contrast, headings, landmarks ([652e159](https://github.com/sophiie-ai/clautch/commit/652e159b16985ffe2b36391d4cfd977bb62ebe37))
* include iCloud entitlements in release re-sign step ([2fea96d](https://github.com/sophiie-ai/clautch/commit/2fea96d82938778e0c18c02ab171429b89e70a37))
* initialize localState on room join and before sending reactions/chat ([16398b9](https://github.com/sophiie-ai/clautch/commit/16398b9626453e64cca94e03b19444dbfd0d43ea))
* keep Sparkle update windows in front throughout entire flow ([768bbc5](https://github.com/sophiie-ai/clautch/commit/768bbc52977eb2bebd3cf275dafaa886107a6ccf))
* notch sim panel needs explicit width: 100% ([7230f4a](https://github.com/sophiie-ai/clautch/commit/7230f4a29c3b8e0bcd3119d8c9916137c13e6237))
* notch simulation uses fixed height and border for visibility ([447b162](https://github.com/sophiie-ai/clautch/commit/447b162deed54e914b0884b38da509c930e85ca6))
* panel extends to screen top, fix event log overflow, wider panel ([eb5e384](https://github.com/sophiie-ai/clautch/commit/eb5e3846be2e552bb57fd04a1e3108e279317dd2))
* position hidden DMG items off-screen, delete .fseventsd ([c06a157](https://github.com/sophiie-ai/clautch/commit/c06a157d99fc53d14da0030c02f01731797cc692))
* prevent CloudKit SIGTRAP crash, keep provisioning profile for iCloud ([643eeec](https://github.com/sophiie-ai/clautch/commit/643eeecc7dd4587be8ede5a8d4b04de9ee88e433))
* prevent crash on launch when CloudKit entitlement is missing ([35fbbc3](https://github.com/sophiie-ai/clautch/commit/35fbbc317d2eaf7fca45576f87f1b60fdf3ed422))
* prevent crash when event log disabled (invalid star range) ([a010d1c](https://github.com/sophiie-ai/clautch/commit/a010d1c9230a7fcc11282e30c44a3ad8e4a5f54a))
* prevent duplicate Room and Change Creature windows ([223b8fb](https://github.com/sophiie-ai/clautch/commit/223b8fb2d2c32217285f20c21422c52415e27819))
* raise contrast ratios to pass WCAG AA (4.5:1 minimum) ([9813b27](https://github.com/sophiie-ai/clautch/commit/9813b274ee61969fa73353030f4200aabcb4a056))
* refine expanded panel overlay styles ([4e772b2](https://github.com/sophiie-ai/clautch/commit/4e772b20f22ac45e2cc5a53dd4fd926fff72e5ba))
* release-please now bumps minor version on feat commits ([257e53b](https://github.com/sophiie-ai/clautch/commit/257e53b654118fd30c9a0afd31d72d6a912b251a))
* reliable DMG creation with manual hdiutil + AppleScript ([b3e0e3c](https://github.com/sophiie-ai/clautch/commit/b3e0e3c7ec88b4c7d1c4f7aad34b3f8a3f110778))
* remove animated menu bar icon, keep default Clautch icon ([b664f06](https://github.com/sophiie-ai/clautch/commit/b664f065846bcfa5fa291101208ea34624eae7ff))
* remove aps-environment from release entitlements (requires provisioning profile) ([0b09cfd](https://github.com/sophiie-ai/clautch/commit/0b09cfd77fdc63b660ef0d341c9e2d2b25c47324))
* remove iCloud entitlements from release signing, init CloudKit directly ([1fec81a](https://github.com/sophiie-ai/clautch/commit/1fec81a44e93fabf6f3e60cf70a61d1f42a0b6a0))
* remove install steps from landing page ([a7865a4](https://github.com/sophiie-ai/clautch/commit/a7865a478556e10fcc6f97ac64bf1c5f6de084ce))
* restore widget when onboarding is dismissed without completing ([69fff6f](https://github.com/sophiie-ai/clautch/commit/69fff6f78888cb1a17b40e73b670115c52c58f1b))
* return to accessory mode on resign active, not window close ([3844c14](https://github.com/sophiie-ai/clautch/commit/3844c14f49ecde26bb63651abf5eb5cfa7585bc3))
* set CFBundleVersion in Info.plist before build, force Sparkle windows to front ([b223e81](https://github.com/sophiie-ai/clautch/commit/b223e811c89cc1df03a88e2627f5ec59778ee319))
* set menu bar icon as template image for proper visibility ([3a90568](https://github.com/sophiie-ai/clautch/commit/3a90568c7ef7229fe9fd744e57780db5869edc07))
* settings tabs now clickable on entire tab area, not just the icon ([0712e07](https://github.com/sophiie-ai/clautch/commit/0712e070349936eb590f408e9138a28cd4fd8f5c))
* settings uses toolbar-style tab bar, and fix widget hit testing ([7a9d84e](https://github.com/sophiie-ai/clautch/commit/7a9d84e2d61452f647f580fd4aa4d39bbaa02438))
* settings window now centers on first open and comes to front reliably ([c41f770](https://github.com/sophiie-ai/clautch/commit/c41f7704206c417c6b96e0cd5151c6931c1499b7))
* settings window now opens reliably using WindowCoordinator ([cc747df](https://github.com/sophiie-ai/clautch/commit/cc747df4acdec14b1a38c3a0f95415577c785462))
* smaller panel when event log disabled, better content padding ([e50b2ce](https://github.com/sophiie-ai/clautch/commit/e50b2cec8caae48ede81cb5361cba8ff472776fc))
* stable creature positioning with overlay-based chat and reactions ([11723e4](https://github.com/sophiie-ai/clautch/commit/11723e4091129cf64002aa7cda7edb4d5710bbbf))
* stop Sparkle update check from repeatedly stealing focus ([71e7fd8](https://github.com/sophiie-ai/clautch/commit/71e7fd8812eeb3d76d50bf7e9eb1272b93780c60))
* update appcast signature for v0.1.0 with icon ([3f5c9e0](https://github.com/sophiie-ai/clautch/commit/3f5c9e0604064de431550f20d22c2e47c4117c70))
* update hook format to matcher+hooks structure ([00e77b6](https://github.com/sophiie-ai/clautch/commit/00e77b629e712586c141dc61a765e9e0d5b7cb18))
* update install steps and footer copy ([400705d](https://github.com/sophiie-ai/clautch/commit/400705d7c290504a9b7ef33bf73886a006d6a5f0))
* use 2px top padding on event log overlay ([7b0cc45](https://github.com/sophiie-ai/clautch/commit/7b0cc45e6739b347af886e598d4a78979e6b61f6))
* use build number in sparkle:version for correct update comparison ([262ab4c](https://github.com/sophiie-ai/clautch/commit/262ab4cc97808991fa77f07a8bd26b0817e3bff4))
* use CloudKit entitlements for re-sign step to match provisioning profile ([adbe3e6](https://github.com/sophiie-ai/clautch/commit/adbe3e64373720561564d2035c13c3fb4926cc49))
* use Developer ID manual signing in CI archive step ([b14e9f4](https://github.com/sophiie-ai/clautch/commit/b14e9f4d2616c16ab8b95a9f58e1ef0cfd14a529))
* use release entitlements for CI archive (no provisioning profile needed) ([60861a6](https://github.com/sophiie-ai/clautch/commit/60861a6438e2ca7d260530daebae9594836526ab))
* use separate archive entitlements without iCloud for CI xcodebuild ([abb1a8d](https://github.com/sophiie-ai/clautch/commit/abb1a8d9df09efa94e49ac569988490e1c8e12e3))
* use unique DMG volume name to avoid stale mount conflicts ([8eacac1](https://github.com/sophiie-ai/clautch/commit/8eacac18c5068422050132aa51847e0b03df5ba8))


### Performance

* reduce CPU usage when panel is collapsed ([d6e2a21](https://github.com/sophiie-ai/clautch/commit/d6e2a2149086b783cf309b4ff855752714f6f7d7))


### Security

* invite tokens, concurrent sync, socket UID check ([58a011c](https://github.com/sophiie-ai/clautch/commit/58a011c8ba6881d55f8befd4e8b7a371372d2510))
* sanitize strings, expand signatures, pause sync, wire animation reduction ([7d884d7](https://github.com/sophiie-ai/clautch/commit/7d884d75460b82f6cd1ae19db1b38c5004611851))

## [0.15.0](https://github.com/sophiie-ai/clautch/compare/v0.14.0...v0.15.0) (2026-04-06)


### Features

* fix daily quest counters, lock indicators in onboarding, creature pet interaction ([1548f0a](https://github.com/sophiie-ai/clautch/commit/1548f0a99c1ad15f43c948a68443270cc67a5237))

## [0.14.0](https://github.com/sophiie-ai/clautch/compare/v0.13.1...v0.14.0) (2026-04-06)


### Features

* render attention indicators as pixel art inside creature canvas ([5e79133](https://github.com/sophiie-ai/clautch/commit/5e791337de202f5baedc5521d93f2e26f07bb488))

## [0.13.1](https://github.com/sophiie-ai/clautch/compare/v0.13.0...v0.13.1) (2026-04-06)


### Bug Fixes

* restore widget when onboarding is dismissed without completing ([69fff6f](https://github.com/sophiie-ai/clautch/commit/69fff6f78888cb1a17b40e73b670115c52c58f1b))

## [0.13.0](https://github.com/sophiie-ai/clautch/compare/v0.12.0...v0.13.0) (2026-04-06)


### Features

* add prestige system, weekly challenges, and exponential XP curve ([c749905](https://github.com/sophiie-ai/clautch/commit/c7499052b18706b0fa7a9249a81ac76ae42cfacb))

## [0.12.0](https://github.com/sophiie-ai/clautch/compare/v0.11.0...v0.12.0) (2026-04-06)


### Features

* deepen gamification — XP scaling, 11 new achievements, daily quests, 6 evolution stages ([1fb9e0f](https://github.com/sophiie-ai/clautch/commit/1fb9e0f4820803cf275818780da015c4b7f1dd46))

## [0.11.0](https://github.com/sophiie-ai/clautch/compare/v0.10.0...v0.11.0) (2026-04-05)


### Features

* support non-notch Macs with virtual top-center panel ([d963e85](https://github.com/sophiie-ai/clautch/commit/d963e85eb1bb8e2a2caec220ceaf413a1c401615))

## [0.10.0](https://github.com/sophiie-ai/clautch/compare/v0.9.1...v0.10.0) (2026-04-05)


### Features

* add 5 new creature features — accessories, seasons, mood journal, interactions, sharing ([f413582](https://github.com/sophiie-ai/clautch/commit/f413582531b3895f2b30eb4237eaf17ea3a27583))

## [0.9.1](https://github.com/sophiie-ai/clautch/compare/v0.9.0...v0.9.1) (2026-04-04)


### Bug Fixes

* improve accessibility score — contrast, headings, landmarks ([652e159](https://github.com/sophiie-ai/clautch/commit/652e159b16985ffe2b36391d4cfd977bb62ebe37))
* raise contrast ratios to pass WCAG AA (4.5:1 minimum) ([9813b27](https://github.com/sophiie-ai/clautch/commit/9813b274ee61969fa73353030f4200aabcb4a056))

## [0.9.0](https://github.com/sophiie-ai/clautch/compare/v0.8.0...v0.9.0) (2026-04-04)


### Features

* add gamification system with streaks, achievements, and creature evolution ([300d615](https://github.com/sophiie-ai/clautch/commit/300d6159ca93f2e013e331a167cebe5919423bc1))


### Bug Fixes

* add sitemap.xml, robots.txt, and canonical tags for SEO ([2ee9c56](https://github.com/sophiie-ai/clautch/commit/2ee9c569ce6a84e462d2b1714d9c94744423ec6d))

## [0.8.0](https://github.com/sophiie-ai/clautch/compare/v0.7.0...v0.8.0) (2026-04-04)


### Features

* add screenshot of creature in notch to landing page ([b7a4690](https://github.com/sophiie-ai/clautch/commit/b7a469004b740409d416354f01284724934edcc0))
* interactive notch simulation with 3 creatures, wandering, and reactions ([d398cea](https://github.com/sophiie-ai/clautch/commit/d398cea9f2a757031e754c8b7d1f7661439b587c))
* replace screenshot with animated canvas notch simulation ([acba370](https://github.com/sophiie-ai/clautch/commit/acba37082c546ca596b91c623c8b54fba19e6504))


### Bug Fixes

* notch sim panel needs explicit width: 100% ([7230f4a](https://github.com/sophiie-ai/clautch/commit/7230f4a29c3b8e0bcd3119d8c9916137c13e6237))
* notch simulation uses fixed height and border for visibility ([447b162](https://github.com/sophiie-ai/clautch/commit/447b162deed54e914b0884b38da509c930e85ca6))
* remove install steps from landing page ([a7865a4](https://github.com/sophiie-ai/clautch/commit/a7865a478556e10fcc6f97ac64bf1c5f6de084ce))
* update install steps and footer copy ([400705d](https://github.com/sophiie-ai/clautch/commit/400705d7c290504a9b7ef33bf73886a006d6a5f0))

## [0.7.0](https://github.com/sophiie-ai/clautch/compare/v0.6.0...v0.7.0) (2026-04-04)


### Features

* changelog page, pipeline diagram, overlay extraction, notification protocol, and 14 new tests ([a65d9b4](https://github.com/sophiie-ai/clautch/commit/a65d9b46fa47dde78f0cb198516a3a4587a5a2a6))
* redesign landing page with animations, SEO, and responsive layout ([e123b8f](https://github.com/sophiie-ai/clautch/commit/e123b8ff272536adcbf5e07508a8e61caa14cae2))


### Bug Fixes

* add favicon and apple-touch-icon to website ([e5f8546](https://github.com/sophiie-ai/clautch/commit/e5f8546b249cd1ff527cc091d681f69327efb4c8))

## [0.6.0](https://github.com/sophiie-ai/clautch/compare/v0.5.1...v0.6.0) (2026-04-04)


### Features

* add Vercel Web Analytics to landing page ([3ba4cf0](https://github.com/sophiie-ai/clautch/commit/3ba4cf0299c79ec48b42584aa8bf7e339c5981ed))


### Security

* sanitize strings, expand signatures, pause sync, wire animation reduction ([7d884d7](https://github.com/sophiie-ai/clautch/commit/7d884d75460b82f6cd1ae19db1b38c5004611851))

## [0.5.1](https://github.com/sophiie-ai/clautch/compare/v0.5.0...v0.5.1) (2026-04-03)


### Bug Fixes

* hide notch panel during Mission Control and Expose ([ac31d01](https://github.com/sophiie-ai/clautch/commit/ac31d015d36d0a02d6328e4eaf35658a17381f91))

## [0.5.0](https://github.com/sophiie-ai/clautch/compare/v0.4.0...v0.5.0) (2026-04-03)


### Features

* code cleanup, file extraction, smooth transitions, and chat persistence ([c1173b4](https://github.com/sophiie-ai/clautch/commit/c1173b449a7016cf95d16affd6f689ba3065305b))

## [0.4.0](https://github.com/sophiie-ai/clautch/compare/v0.3.0...v0.4.0) (2026-04-03)


### Features

* extract CreatureIslandOverlay and add smooth state transition animation ([bc8386c](https://github.com/sophiie-ai/clautch/commit/bc8386cfe3c207966556c513395c1d9ebe2e8d10))

## [0.3.0](https://github.com/sophiie-ai/clautch/compare/v0.2.55...v0.3.0) (2026-04-03)


### Features

* permission indicator, creature personalities, layout refactor, contrast fix, and pipeline tests ([c8bc0ea](https://github.com/sophiie-ai/clautch/commit/c8bc0ea257e2e97165ea01b731390168ecaf87e8))


### Bug Fixes

* release-please now bumps minor version on feat commits ([257e53b](https://github.com/sophiie-ai/clautch/commit/257e53b654118fd30c9a0afd31d72d6a912b251a))

## [0.2.55](https://github.com/sophiie-ai/clautch/compare/v0.2.54...v0.2.55) (2026-04-03)


### Features

* needs-input indicator when session awaits human response ([1823b54](https://github.com/sophiie-ai/clautch/commit/1823b54032895da988b39605d0e0dda7d9487132))
* random micro-animations when collapsed (hop and tilt) ([aa14eb5](https://github.com/sophiie-ai/clautch/commit/aa14eb5fb8b2f2afb8e6e46a9c0ae7aa728d9015))

## [0.2.54](https://github.com/sophiie-ai/clautch/compare/v0.2.53...v0.2.54) (2026-04-03)


### Features

* polished onboarding fly-to-notch animation, creatures beside notch when collapsed ([3fcda20](https://github.com/sophiie-ai/clautch/commit/3fcda2023658e549c67638e133c96568a4d0f2f7))


### Bug Fixes

* changing creature no longer quits app ([899c4e0](https://github.com/sophiie-ai/clautch/commit/899c4e04c332590a8b92fe565e55e26545ca01e0))

## [0.2.53](https://github.com/sophiie-ai/clautch/compare/v0.2.52...v0.2.53) (2026-04-03)


### Bug Fixes

* all windows now center on first show and come to front reliably ([a6a55ec](https://github.com/sophiie-ai/clautch/commit/a6a55ecbc01d014d880cc8fd7b03b855273dea79))

## [0.2.52](https://github.com/sophiie-ai/clautch/compare/v0.2.51...v0.2.52) (2026-04-03)


### Bug Fixes

* changing creature no longer causes app to quit ([2b4ac91](https://github.com/sophiie-ai/clautch/commit/2b4ac91e8c3f9f7ab5c3c1b000d26bf64c06e81c))
* collapsed clip shape uses correct y origin (top of view, not bottom) ([a3663b9](https://github.com/sophiie-ai/clautch/commit/a3663b980709902ff62e13412b789f53869da5b3))

## [0.2.51](https://github.com/sophiie-ai/clautch/compare/v0.2.50...v0.2.51) (2026-04-03)


### Bug Fixes

* collapsed widget clips to notch height and lowers window level ([534d0ea](https://github.com/sophiie-ai/clautch/commit/534d0ea8ec6b3db8a3e5247bf680d7c365e4dbbf))

## [0.2.50](https://github.com/sophiie-ai/clautch/compare/v0.2.49...v0.2.50) (2026-04-03)


### Bug Fixes

* collapsed widget stays within menu bar height, no peek below ([7d5bfae](https://github.com/sophiie-ai/clautch/commit/7d5bfaef6c3b1207ea8c64adbb12e2557766dae8))
* settings tabs now clickable on entire tab area, not just the icon ([0712e07](https://github.com/sophiie-ai/clautch/commit/0712e070349936eb590f408e9138a28cd4fd8f5c))

## [0.2.49](https://github.com/sophiie-ai/clautch/compare/v0.2.48...v0.2.49) (2026-04-03)


### Bug Fixes

* remove animated menu bar icon, keep default Clautch icon ([b664f06](https://github.com/sophiie-ai/clautch/commit/b664f065846bcfa5fa291101208ea34624eae7ff))
* settings uses toolbar-style tab bar, and fix widget hit testing ([7a9d84e](https://github.com/sophiie-ai/clautch/commit/7a9d84e2d61452f647f580fd4aa4d39bbaa02438))

## [0.2.48](https://github.com/sophiie-ai/clautch/compare/v0.2.47...v0.2.48) (2026-04-03)


### Bug Fixes

* collapsed panel only intercepts clicks in notch/menubar strip ([86df880](https://github.com/sophiie-ai/clautch/commit/86df880f9bec015b6da0b14e983a1174c8553c6b))
* display picker in Settings now properly recreates panel on selected screen ([1f75683](https://github.com/sophiie-ai/clautch/commit/1f756836f24c219d0ae158989c445138e30e8714))
* expanded panel only intercepts clicks within visible island bounds ([f5bba52](https://github.com/sophiie-ai/clautch/commit/f5bba52489b82259ec9eefc706a739121e8b6bb4))
* settings window now opens reliably using WindowCoordinator ([cc747df](https://github.com/sophiie-ai/clautch/commit/cc747df4acdec14b1a38c3a0f95415577c785462))

## [0.2.47](https://github.com/sophiie-ai/clautch/compare/v0.2.46...v0.2.47) (2026-04-03)


### Features

* click peer creature to wave, and animated onboarding-to-notch transition ([22baf1c](https://github.com/sophiie-ai/clautch/commit/22baf1cf7ed75763544c25dd1590c28fc7694fef))

## [0.2.46](https://github.com/sophiie-ai/clautch/compare/v0.2.45...v0.2.46) (2026-04-03)


### Features

* display picker in Settings for choosing which screen shows the notch panel ([57c0b54](https://github.com/sophiie-ai/clautch/commit/57c0b549a07ab58fe00882592b84fe5cd3aa40ed))
* stepped onboarding flow with skip button, and creature hover bounce ([91dfab1](https://github.com/sophiie-ai/clautch/commit/91dfab1b15ca9ebb24b3a26c7401d9dfa12d8b4e))


### Bug Fixes

* settings window now centers on first open and comes to front reliably ([c41f770](https://github.com/sophiie-ai/clautch/commit/c41f7704206c417c6b96e0cd5151c6931c1499b7))

## [0.2.45](https://github.com/sophiie-ai/clautch/compare/v0.2.44...v0.2.45) (2026-04-03)


### Features

* walk easing, mood sparkline, sound effects, WindowCoordinator, mock tests, and Swift 6 concurrency ([e125062](https://github.com/sophiie-ai/clautch/commit/e1250624c2a5f3a302b91bab8e9e3ce3dda80b35))


### Bug Fixes

* guard mock CloudKit tests for missing UserProfile on CI ([a7ac95c](https://github.com/sophiie-ai/clautch/commit/a7ac95c847de8f2416dfcbb95ed4beef51a36881))

## [0.2.44](https://github.com/sophiie-ai/clautch/compare/v0.2.43...v0.2.44) (2026-04-03)


### Features

* deep links, CloudKit protocol, notification grouping, menubar creature, sky interpolation, typing indicator, creature settings, walk paths, menu reorg, and tests ([04d68fd](https://github.com/sophiie-ai/clautch/commit/04d68fdec23112483907250ce0dc9a851c434032))

## [0.2.43](https://github.com/sophiie-ai/clautch/compare/v0.2.42...v0.2.43) (2026-04-02)


### Features

* keychain confirmation dialog and README update ([87e1759](https://github.com/sophiie-ai/clautch/commit/87e1759959f6b99b20dac5fadc42f142765ae2cd))

## [0.2.42](https://github.com/sophiie-ai/clautch/compare/v0.2.41...v0.2.42) (2026-04-02)


### Features

* settings window, accessibility labels, window conventions, and spacing fixes ([74312a0](https://github.com/sophiie-ai/clautch/commit/74312a03a9102c8accd4cab5fb93acd10e979fc9))

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
