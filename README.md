<div align="center">

```
██████╗  █████╗ ███████╗███████╗██╗     ███████╗
██╔══██╗██╔══██╗██╔════╝██╔════╝██║     ██╔════╝
██████╔╝███████║█████╗  █████╗  ██║     █████╗  
██╔══██╗██╔══██║██╔══╝  ██╔══╝  ██║     ██╔══╝  
██║  ██║██║  ██║██║     ██║     ███████╗███████╗
╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝╚══════╝
```

</div>

<div align="center">

**A provably fair, decentralized raffle smart contract built with Solidity & Foundry.**  
*The house doesn't win here. There is no house.*

[![Solidity](https://img.shields.io/badge/Solidity-%5E0.8.18-363636?style=for-the-badge&logo=solidity&logoColor=white)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-FF4444?style=for-the-badge&logo=ethereum&logoColor=white)](https://book.getfoundry.sh/)
[![Chainlink VRF](https://img.shields.io/badge/Chainlink-VRF_V2-375BD2?style=for-the-badge&logo=chainlink&logoColor=white)](https://docs.chain.link/vrf)
[![Chainlink Automation](https://img.shields.io/badge/Chainlink-Automation-375BD2?style=for-the-badge&logo=chainlink&logoColor=white)](https://docs.chain.link/chainlink-automation)
[![License: MIT](https://img.shields.io/badge/License-MIT-2CFF05?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Sepolia](https://img.shields.io/badge/Network-Sepolia_Testnet-626890?style=for-the-badge&logo=ethereum&logoColor=white)](https://sepolia.etherscan.io/)

</div>

---

## 📖 Table of Contents

- [What Is This?](#-what-is-this)
- [How It Works](#-how-it-works)
- [Use Cases](#-use-cases)
- [Workflow Diagram](#-workflow-diagram)
- [Prerequisites](#-prerequisites)
- [Installation & Setup](#-installation--setup)
- [How to Use](#-how-to-use)
- [All Commands Explained](#-all-commands-explained)
- [Environment Variables](#-environment-variables)
- [Project Structure](#-project-structure)
- [Resources](#-resources)
- [Credits](#-credits)

---

## 🧠 What Is This?

Every lottery in history has had one thing in common — someone behind the curtain who could pull a string. A casino, a government, a foundation. An entity with the power to decide who wins, when, and why.

**"Decentralized Raffle"** removes that entity entirely.

This is a provably fair, fully autonomous decentralized lottery deployed on the Ethereum blockchain. Players enter by sending ETH. After a set time interval, a winner is picked using **Chainlink VRF V2** #cryptographically verifiable randomness that nobody, including the contract deployer, can predict or manipulate. The entire pot moves to the winner's wallet automatically. No operator. No withdrawal delay. No fees skimmed off the top.

The contract runs itself. The randomness is provable on-chain. The payout is instant.

> *"Casinos have algorithms too. The difference is — theirs are secret."*

---

## ⚙️ How It Works

The contract operates on four interlocking pillars. Each one exists because removing it would create a vector for manipulation.

### 1. 🎟️ Entering the Raffle
Any wallet calls `enterRaffle()` and pays the entrance fee in ETH. The contract records the address in a players array on-chain — no database, no backend, no server that can go down or get hacked. Everyone can verify the full list. Send less than the entrance fee and the transaction reverts. No exceptions, no special cases, no admin override.

### 2. ⏰ Automated Upkeep — Chainlink Automation
The contract implements `checkUpkeep()` and `performUpkeep()` — the Chainlink Automation interface. A decentralized network of Chainlink nodes monitors the contract around the clock and calls `performUpkeep()` the moment all conditions align:

- Raffle is in `OPEN` state
- The time interval has elapsed
- At least one player has entered
- The contract holds a non-zero ETH balance

Nobody has to press a button. Nobody can delay it. Nobody can speed it up. It fires when it's supposed to fire, every time, without asking.

### 3. 🎲 Verifiable Randomness — Chainlink VRF V2
This is where most "decentralized" lotteries cut corners — and get exploited. Block hashes, timestamps, miner seeds — all of them can be gamed. Chainlink VRF is different.

When upkeep fires, the contract sends a randomness request to the **VRF Coordinator**. The response arrives in a separate transaction, signed by Chainlink's oracle with a cryptographic proof. That proof is verified on-chain before the number is ever used. If the proof fails, the transaction reverts. The number cannot be front-run. It cannot be re-rolled. It cannot be predicted by anyone — including the people who built this.

### 4. 🏆 Winner Selection & Payout
The random number hits `fulfillRandomWords()`. One line of arithmetic — `players[randomNum % players.length]` — and a winner exists. The full ETH balance of the contract transfers to their wallet in the same transaction. The players list clears. The timestamp resets. The raffle reopens for the next round. Automatic, atomic, irreversible.

---

## 🎯 Use Cases

| Use Case | Description |
|----------|-------------|
| 🧪 **Web3 Learning** | Hands-on with Chainlink VRF, Automation, mock contracts, and Foundry's full testing suite |
| 🎰 **On-Chain Lottery** | Production-grade foundation for any decentralized raffle or lottery dApp |
| 🔬 **Smart Contract Testing** | Unit tests, integration tests, fork tests, and Foundry cheatcodes — all in one project |
| 🤖 **Automation Patterns** | The `checkUpkeep` / `performUpkeep` pattern — how self-executing contracts actually work |
| 🎲 **VRF Integration** | Real example of on-chain verifiable randomness that can't be gamed, front-run, or faked |
| 🚀 **Deployment Practice** | Mock-based local testing vs. live Sepolia — same codebase, environment-aware config |

---

> *"Luck is the last thing no one has figured out how to steal. Until now, it was never verified either."*

---

## 🗺️ Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         RAFFLE FLOW                             │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │   forge build   │  ◄── Compiles all .sol files
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   forge test    │  ◄── Runs unit + integration tests
                    └────────┬────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
       ┌────────────────┐       ┌──────────────────┐
       │  anvil (local) │       │  Sepolia Testnet  │
       │  Mock VRF/Auto │       │  Real Chainlink   │
       └───────┬────────┘       └────────┬─────────┘
               │                         │
               ▼                         ▼
      ┌─────────────────┐    ┌────────────────────────┐
      │  forge script   │    │  make deploySepolia     │
      │  (local deploy) │    │  --verify --broadcast   │
      └───────┬─────────┘    └──────────┬──────────────┘
              │                         │
              └───────────┬─────────────┘
                          │
                          ▼
               ┌─────────────────────┐
               │  Raffle.sol         │
               │  Contract Deployed  │
               └──────────┬──────────┘
                          │
            ┌─────────────┼──────────────┐
            │             │              │
            ▼             ▼              ▼
   ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐
   │ enterRaffle()│ │ checkUpkeep()│ │  performUpkeep()      │
   │              │ │              │ │                        │
   │ • Pay fee    │ │ • Time check │ │ • State → CALCULATING  │
   │ • Push addr  │ │ • Has player │ │ • Request VRF random   │
   │   to array   │ │ • Has ETH    │ │   number from          │
   │ • Emit event │ │ • OPEN state │ │   Chainlink oracle     │
   └──────┬───────┘ └──────┬───────┘ └──────────┬───────────┘
          │                │                     │
          │    Chainlink Automation network       │
          │    monitors checkUpkeep() → fires     │
          │    performUpkeep() automatically      │
          │                                       │
          ▼                                       ▼
   ┌──────────────────────────────────────────────────────────┐
   │                 Chainlink VRF V2 Oracle                  │
   │                                                          │
   │   requestRandomWords() ──► VRF Coordinator               │
   │   fulfillRandomWords()  ◄── Cryptographic proof + number │
   │   winner = players[randomNum % players.length]           │
   │   Full ETH balance transfers → winner instantly          │
   │   Reset players[] + timestamp + state → OPEN             │
   └──────────────────────────────────────────────────────────┘
```

---

## 🛠️ Prerequisites

Before you install anything, make sure you have these tools ready:

| Tool | Purpose | Install |
|------|---------|---------|
| **Git** | Clone the repo | [git-scm.com](https://git-scm.com/) |
| **Foundry** | Compile, test & deploy Solidity | See below |
| **An RPC URL** | Connect to Ethereum nodes | [Alchemy](https://alchemy.com) or [Infura](https://infura.io) |
| **A Wallet Private Key** | Sign transactions | MetaMask or any EVM wallet |
| **Etherscan API Key** | Verify contracts on-chain | [etherscan.io](https://etherscan.io/apis) |
| **Sepolia ETH** | Pay for gas fees on testnet | [Sepolia Faucet](https://sepoliafaucet.com/) |
| **Chainlink VRF Subscription** | Fund randomness requests | [vrf.chain.link](https://vrf.chain.link/) |

### Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Verify the install:

```bash
forge --version
cast --version
anvil --version
```

---

## 📦 Installation & Setup

### 1. Clone the repository

```bash
git clone https://github.com/nxvjot7/decentralized-raffle.git
cd decentralized-raffle
```

### 2. Install dependencies

```bash
forge install
```

Pulls in all submodules — Chainlink contracts, forge-std, everything defined in `.gitmodules`. One command, no manual wiring.

### 3. Set up environment variables

```bash
touch .env
```

Add the following:

```env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
```

> ⚠️ **Security warning:** Never commit your `.env` file. It's already in `.gitignore`, but double-check. Your private key in the wrong hands means your wallet is gone — permanently, with no recourse. That's not a bug. That's the point.

### 4. Load env variables

```bash
source .env
```

### 5. Build the project

```bash
forge build
```

Clean compile means you're ready. Errors here mean something is broken before you even start — fix them now, not after you've broadcast a broken contract to a live network.

---

> *"You don't need permission to build on a permissionless network."*

---

## 🚀 How to Use

Once deployed — locally via Anvil or live on Sepolia — here's how you interact with the contract from the terminal, step by step.

---

### Step 1 — Spin up a local node

```bash
anvil
```

Launches a local Ethereum node at `http://localhost:8545` with 10 pre-funded wallets. The deployment script detects the local environment and automatically deploys **mock VRF and mock Automation** contracts — full raffle cycle, zero LINK spent.

---

### Step 2 — Deploy the contract

**Locally (Anvil):**

```bash
forge script script/DeployRaffle.s.sol:DeployRaffle \
  --rpc-url http://localhost:8545 \
  --private-key <ANVIL_PRIVATE_KEY> \
  --broadcast
```

**On Sepolia (single command):**

```bash
make deploySepolia
```

The contract address prints to terminal after a successful deploy. Save it — every command below needs it.

> 📌 **For Sepolia:** Your Chainlink VRF subscription must be funded with LINK, and the deployed contract address must be registered as a consumer at [vrf.chain.link](https://vrf.chain.link/). Without this, `fulfillRandomWords()` is never called and the raffle never resolves. It just sits there, collecting entries, going nowhere.

---

### Step 3 — Enter the raffle

```bash
cast send <CONTRACT_ADDRESS> "enterRaffle()" \
  --value 0.01ether \
  --private-key $PRIVATE_KEY \
  --rpc-url $SEPOLIA_RPC_URL
```

Your address is pushed into the on-chain players array. Send from multiple wallets to simulate a real round. Send less than the entrance fee and the transaction reverts — the contract doesn't negotiate.

---

### Step 4 — Check the entrance fee

```bash
cast call <CONTRACT_ADDRESS> "getEntranceFee()" \
  --rpc-url $SEPOLIA_RPC_URL
```

Returns the minimum ETH in wei. Convert it: `cast --to-unit <WEI> ether`.

---

### Step 5 — Check the player count

```bash
cast call <CONTRACT_ADDRESS> "getNumberOfPlayers()" \
  --rpc-url $SEPOLIA_RPC_URL
```

How many wallets are in the current round. This is the denominator when the winner gets selected.

---

### Step 6 — Inspect a specific player

```bash
cast call <CONTRACT_ADDRESS> "getPlayer(uint256)" 0 \
  --rpc-url $SEPOLIA_RPC_URL
```

Pass an index to retrieve a player's address. Iterate from `0` to `getNumberOfPlayers() - 1` to walk the entire list.

---

### Step 7 — Check the raffle state

```bash
cast call <CONTRACT_ADDRESS> "getRaffleState()" \
  --rpc-url $SEPOLIA_RPC_URL
```

`0` = `OPEN`. Entries accepted. `1` = `CALCULATING`. VRF response is in flight — entries are locked until the random number lands and the winner is resolved. Trying to enter during `CALCULATING` reverts.

---

### Step 8 — Check the last timestamp

```bash
cast call <CONTRACT_ADDRESS> "getLastTimeStamp()" \
  --rpc-url $SEPOLIA_RPC_URL
```

Unix timestamp of when the current round began. The automation network uses this to calculate whether enough time has elapsed to trigger upkeep.

---

### Step 9 — Check the most recent winner

```bash
cast call <CONTRACT_ADDRESS> "getRecentWinner()" \
  --rpc-url $SEPOLIA_RPC_URL
```

The wallet that walked away with the last pot. Stored on-chain. Auditable by anyone, forever.

---

### Step 10 — Verify the contract balance

```bash
cast balance <CONTRACT_ADDRESS> --rpc-url $SEPOLIA_RPC_URL
```

The live pot. Grows with every entry. Drops to `0` after the winner is paid — because every last wei goes to them. No platform cut. No deployer fee. Nothing held back.

---

### Step 11 — Convert units

```bash
# Wei to Ether
cast --to-unit 10000000000000000 ether

# Ether to Wei
cast --to-unit 0.01ether wei
```

---

### Step 12 — Inspect on Etherscan

Every transaction leaves a permanent, public, unalterable trail:

```
https://sepolia.etherscan.io/tx/<TX_HASH>
```

If deployed with `--verify`, the full source code is publicly readable at:

```
https://sepolia.etherscan.io/address/<CONTRACT_ADDRESS>#code
```

Open code. Open data. Nothing to hide. That's the whole philosophy.

---

> *"On-chain means forever. There's no undo button, no support ticket, no refund policy. Read before you sign."*

---

## 🧰 All Commands Explained

### 🔨 Build

```bash
forge build
```
Compiles all Solidity source files in `src/`. Outputs ABI, bytecode, and metadata to `out/`. Run this first — always. It catches type errors, interface mismatches, and import failures before they become on-chain surprises.

---

### 🧪 Test

```bash
forge test
```
Runs the full test suite against a local in-memory EVM. Mock VRF and mock Automation handle the Chainlink dependencies. Fast. Free. No testnet required.

```bash
forge test -vvvv
```
Maximum verbosity. Every call, every storage write, every revert reason — decoded and printed. Use this when a test fails and "it just doesn't work" isn't an acceptable answer.

```bash
forge test --fork-url $SEPOLIA_RPC_URL
```
Forks live Sepolia state and runs integration tests against real Chainlink infrastructure. Required to verify your contract works with the actual VRF Coordinator — not just a mock that agrees with everything.

---

### 📐 Format

```bash
forge fmt
```
Auto-formats all `.sol` files to Foundry's style conventions. Run before every commit. Consistency is legibility for the next person reading your code.

---

### ⛽ Gas Snapshot

```bash
forge snapshot
```
Runs all tests and records gas cost per function into `.gas-snapshot`. Commit this file. If a future change silently inflates gas usage, the diff exposes it immediately — before it hits production.

---

### ⛓️ Local Node

```bash
anvil
```
Spins up a local Ethereum node at `http://localhost:8545` with 10 funded test accounts. The deployment script detects local chainId and deploys mock Chainlink contracts automatically. No subscription. No LINK. Full coverage.

---

### 🔧 Cast

```bash
cast send    # Write — call state-changing functions, broadcast transactions
cast call    # Read  — query on-chain state without spending gas
cast balance # Check the ETH balance of any address
cast --to-unit # Convert between wei, gwei, and ether
```

`cast` is your CLI key to every deployed contract. Every interaction in the [How to Use](#-how-to-use) section above runs through it.

---

### 🚀 Deploy (Sepolia)

```bash
make deploySepolia
```
One command. Reads `.env`, deploys, broadcasts, verifies. No flags to remember. No steps to miss.

---

### ❓ Need More?

```bash
forge --help
anvil --help
cast --help
```

Or read the actual docs: **[book.getfoundry.sh](https://book.getfoundry.sh/)**

---

## 🔑 Environment Variables

| Variable | Description |
|----------|-------------|
| `SEPOLIA_RPC_URL` | Your Alchemy/Infura RPC endpoint for Sepolia testnet |
| `PRIVATE_KEY` | Private key of the deployer wallet (with `0x` prefix) |
| `ETHERSCAN_API_KEY` | API key for contract verification on Etherscan |

---

## 🗂️ Project Structure

```
decentralized-raffle/
├── .github/
│   └── workflows/          # CI/CD pipelines (GitHub Actions)
├── lib/                    # Submodule dependencies (Chainlink, forge-std)
├── script/
│   ├── DeployRaffle.s.sol  # Deployment script — local mocks vs live Sepolia, auto-detected
│   └── Interactions.s.sol  # VRF subscription creation, funding, consumer registration
├── src/
│   └── Raffle.sol          # The contract. Read it. Understand it. Trust it.
├── test/
│   ├── unit/               # Unit tests — isolated, fast, mock-based
│   └── integration/        # Integration tests — fork Sepolia, real Chainlink
├── .env                    # Local secrets (never commit this)
├── .gas-snapshot           # Gas usage per function, tracked across every change
├── foundry.toml            # Foundry configuration
├── Makefile                # Shortcut commands
└── README.md               # You are here
```

---

## 📚 Resources

- [Foundry Book](https://book.getfoundry.sh/) — official Foundry documentation
- [Chainlink VRF Docs](https://docs.chain.link/vrf) — how verifiable randomness actually works
- [Chainlink Automation Docs](https://docs.chain.link/chainlink-automation) — self-executing contracts
- [Solidity Docs](https://docs.soliditylang.org/) — the language reference
- [Sepolia Faucet](https://sepoliafaucet.com/) — free Sepolia ETH for testing
- [Etherscan Sepolia](https://sepolia.etherscan.io/) — explore every transaction on-chain
- [VRF Subscription Manager](https://vrf.chain.link/) — fund and manage your VRF subscription

---

## 🏴 Credits

<div align="center">

```
╔══════════════════════════════════════════════╗
║                                              ║
║   Built & maintained by                      ║
║                                              ║
║      NAVJOT SINGH                            ║
║          AKA- nxvjot7 / Ghost                ║
║                                              ║
║   "VERIFIABLE.                               ║
║           AUTOMATED.                         ║
║                   UNSTOPPABLE.               ║
║                              FAIR.           ║
║                                              ║
║       < PROJECT - DECENTRALIZED RAFFLE  >    ║
║                                              ║
╚══════════════════════════════════════════════╝
```

</div>

<div align="center">


[![GitHub](https://img.shields.io/badge/GitHub-nxvjot7-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/nxvjot7)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-nxvjot7-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/nxvjot7)
[![Medium](https://img.shields.io/badge/Medium-nxvjot7-12100E?style=for-the-badge&logo=medium&logoColor=white)](https://medium.com/@nxvjot7)
[![YouTube](https://img.shields.io/badge/YouTube-nxvjot7-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://youtube.com/@nxvjot7)

---

![visitor badge](https://komarev.com/ghpvc/?username=nxvjot7&color=2CFF05&style=for-the-badge&label=VISITORS)

<sub>Built with ⚡ using Solidity + Foundry + Chainlink on Ethereum</sub>

---

<b><i>~ Ghost was here ;</b></i>

</div>
