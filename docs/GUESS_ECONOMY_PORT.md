

## Guess economy and permanent-upgrade pass (2026-11-08)

The branch `port/gtn1-guess-economy` ports the production formulas from GTN1's shared `GuessEconomyDecisionRules`, `GuessRewardRules`, `FrenzyRules`, `CriticalChanceRules` and `GameEngine` into Dart:
- Correct-guess base reward is 100 Money per current range unit, with GTN1's minimum reward of 10.
- Streak rewards use the source's 10% per existing streak count.
- Frenzy starts at a five-guess streak, adds 0.25× per five-guess tier and caps at 5×.
- Critical hits use the source's 5× reward multiplier and 5% base chance plus 1% per Critical Precision Prestige level. Golden Guess guarantees the critical on every tenth guess.
- The reward multiplier upgrade uses the source's 1 + 0.25 × level formula.
- Difficulty, mutator, talent, trait and permanent Money multipliers are applied in the same order as the source engine, including the minimum-reward floor before permanent Money multipliers.
- Prestige Money Boost and Ultra Money Boost now compound on every correct-guess reward.
- Prestige Gain Boost, Ultra Gain Boost and Prestige Starting Capital are applied to their respective reset transactions. The progression hub previews the boosted reward.
- Ultra Nebula Boost stacks with the Nebula shop boost for Arcade Nebula rewards.
- The original 11 normal, 3 Prestige and 3 Ultra upgrade definitions are bundled and parsed from GTN1 JSON. The Flutter shops expose only the eight upgrades whose gameplay effects have been verified and wired; unused source catalog entries remain bundled but are not sold as if they work.
- Native Flutter Prestige and Ultra upgrade screens now purchase against the correct currency, enforce the canonical cost and level cap, and persist their levels.

Regression tests cover source catalog IDs/prices, reward balance, critical chance, streak/frenzy tiers, permanent multipliers, reset bonuses, starting capital and Nebula stacking. CI validation is required before merge.

Remaining work includes porting the other seven normal-upgrade effects only if their GTN1 production behavior can be established, full shop/automation and minigame behavior, remaining legacy screens/actions, music playback, updater parity and Android/Windows runtime verification. This pass is not a full-port completion claim.
