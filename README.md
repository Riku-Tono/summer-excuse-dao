# Natsu DAO / Summer Governor Demo

A Solidity + Hardhat demo that models "summer-related excuses" as if they were DAO governance proposals. Votes are weighted by mock NFT traits, a mock heat oracle can override outcomes once the cicadas get loud enough, and every proposal costs a small burn of a mock ERC-20 token — all of it running entirely against in-repo mock contracts on a local Hardhat network, with no token sale, no deployment, and no real on-chain activity anywhere.

## ⚠️ Safety Notice

**This is not a real DAO, token, NFT, or financial product.** There is nothing here to buy, stake, claim, or join. The contracts are not deployed to any network — not mainnet, not a public testnet — and there is no plan to deploy them. This repository exists purely as a self-contained code sample to read, compile, and test locally. If you came here looking for an investment opportunity, an airdrop, or a project to participate in, this isn't it — please look elsewhere.

## What This Is / What This Is Not

**This is:**
- A Solidity code sample exploring governance-style mechanics (proposals, voting power, burns, vetoes) through a deliberately silly "summer excuses" theme.
- A Hardhat test suite that exercises the contract logic locally.
- A self-contained, runnable repo meant to be cloned, installed, and tested on your own machine.

**This is not:**
- A real or planned DAO, governance system, or organization.
- A token, NFT collection, or financial instrument of any kind.
- Deployed anywhere — there are no contract addresses, no mainnet or testnet deployment scripts, and no intention to deploy.
- An invitation to invest, participate, vote, or contribute funds.
- Audited, secured, or reviewed for production use in any way.

Every "DAO," "governance," "token," "burn," and "TreasurySpend" reference below describes fictional mechanics built for this demo only.

## Repository Structure

```
.
├── contracts/
│   ├── SummerGovernorV04.sol     # Main demo governance contract
│   ├── MockNatsuToken.sol        # Mock ERC-20 used for proposal/excuse burns
│   ├── MockGenesisNFT.sol        # Mock NFT used as the voting-power source
│   └── MockHeatOracle.sol        # Mock oracle feeding temperature/cicada data
├── test/
│   └── NatsuGovernorV04.test.js  # Hardhat test suite
├── hardhat.config.js
├── package.json
└── README.md
```

All three `Mock*.sol` contracts exist solely to satisfy the interfaces that `SummerGovernorV04` expects in tests. They are not standins for any real token, NFT, or oracle — they're test fixtures, full stop.

## Install and Test

Requires Node.js and npm.

```bash
npm install
npm test
```

This installs `hardhat` and `@nomicfoundation/hardhat-toolbox`, then runs the test suite in `test/NatsuGovernorV04.test.js` against a local, in-memory Hardhat network. Nothing leaves your machine.

## Contract Overview

`SummerGovernorV04.sol` is the centerpiece. It defines a `Proposal` struct and five proposal types (`SummerExtension`, `BugForgiveness`, `NewBugMint`, `TreasurySpend`, `CourtAppeal`), and wires together three mock dependencies:

- **`IGenesisNFT`** — supplies `votingPower()` based on NFT balance and a handful of named "bug" traits (`hasSleepCycleBug`, `hasLegendaryTripBug`, `hasWalletBug`, `hasSummerRoot`), each adding bonus weight for specific proposal types.
- **`INatsuToken`** — a mock ERC-20 that gets burned via `burnFrom()` whenever someone creates a proposal (`PROPOSAL_BURN`) or files an "excuse" (`MIN_EXCUSE_BURN` minimum).
- **`IHeatOracle`** — supplies `currentTemperature()` and `cicadaLevel()`. When `cicadaLevel()` crosses 70, `cicadaOverride()` can mark a proposal as "probably summer" and boost its yes-votes by 30%.

Core flows:
- `createProposal(...)` — burns Natsu tokens, checks the caller has voting power for that proposal type, and stores a new proposal with a 7- or 14-day deadline depending on type.
- `createExcuseProposal(excuse, burnAmount)` — a lighter-weight proposal type specifically for logging "excuses," with its own minimum burn and an automatic cicada-level check.
- `vote(id, support)` — one vote per address per proposal, with a 20% bonus to "yes" votes on proposals flagged `summerBiased`.
- `cicadaOverride(id)` — lets anyone nudge a proposal toward passing if the mock oracle's cicada level is high enough.
- `execute(id)` — resolves a proposal after its deadline, respecting any veto and applying the "probably summer" tie-break logic.

It's a compact playground for proposal lifecycles, weighted voting, time-based deadlines, and oracle-influenced outcomes — themed around summer excuses instead of treasury management, because that's more fun to read.

## Limitations / Not Production Ready

This code is a tested demo, not a finished product. Specifically:

- No security audit has been performed, and none is planned.
- Access control is minimal to nonexistent in several functions (e.g., `cicadaOverride` is callable by anyone).
- The mock contracts are simplified stand-ins and do not implement full ERC-20/ERC-721 behavior or any real economic logic.
- There is no deployment tooling for any live network, and none should be added or inferred from this repo.
- Edge cases, gas optimization, and upgrade paths have not been hardened for real-world use.

Treat this as a reading and testing exercise, not a foundation to deploy as-is.

## License

MIT. See contract headers for the SPDX identifier.
