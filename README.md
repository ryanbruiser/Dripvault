DripVault Smart Contract  
A Trustless Time-Based STX Yield Distribution Vault on Stacks

---

Overview
**DripVault** is a Clarity smart contract that enables automated, trustless, and time-based distribution of STX rewards to depositors.  
Users can deposit STX into the vault and earn proportional “drip” rewards over time based on their share of the total liquidity.

The contract is designed to be simple, secure, and fully transparent, making it suitable for micro-yield products, community vaults, cooperative savings, and automated income streams.

---

Features
- **Secure STX Deposits & Withdrawals**  
  Users can deposit and withdraw their STX at any time.

- **Automated Yield Distribution (Drip Rewards)**  
  Rewards are streamed proportionally based on the user’s share of the vault.

- **Admin-Controlled Reward Injection**  
  Admins can add additional STX to the vault to be distributed as yield.

- **Time-Based Accrual Mechanism**  
  Rewards accumulate over time and may be withdrawn by users on demand.

- **Full Transparency**  
  All vault and user balances are publicly readable.

---

Contract Functions

**Public Functions**
| Function | Description |
|---------|-------------|
| `deposit` | Allows a user to deposit STX into the vault. |
| `withdraw` | Allows a user to withdraw both principal and earned rewards. |
| `claim-rewards` | Lets a user withdraw only their accumulated rewards. |
| `add-rewards` | Admin function to inject STX that will be streamed as yield. |

**Read-Only Functions**
| Function | Description |
|---------|-------------|
| `get-vault-stats` | Returns overall vault metrics. |
| `get-user-info` | Returns deposited balance, earned rewards, and share. |
| `get-current-drip-rate` | Computes the current drip reward rate. |

---

Installation & Usage

Requirements
- [Clarinet](https://github.com/hirosystems/clarinet)  
- Stacks Testnet or Devnet environment

Run Tests
```bash
clarinet test
```

Check Contract
```bash
clarinet check
```

Deploy (Devnet)
```bash
clarinet integrate
```

---

Security
DripVault includes:
- Strict input validation  
- Zero-amount protection  
- STX transfer failure handling  
- Overflow-safe math  
- Clear separation of admin and user privileges  

A full security audit is recommended before mainnet deployment.

---

License
This project is open-source and available under the MIT License.

---


