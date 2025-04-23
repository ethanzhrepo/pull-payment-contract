# Subscribe Contract

[中文版](README_cn.md)

A smart contract for authorized ERC20 token deduction in subscription and service fee scenarios.

## Overview

The Subscribe contract provides a solution for services requiring regular subscription fees or on-demand charges from users using ERC20 tokens (such as USDC, DAI, or custom project tokens). It allows an authorized address (the "casher") to "pull" or "deduct" specified amounts of tokens from pre-authorized user addresses on behalf of a designated recipient address.

## Why Not Use the Approve Mechanism Directly?

While the ERC20 standard itself provides an approve mechanism, using it directly has some limitations and risks:

1. **Allowance Management Challenges**: Directly approving a service provider means users must trust that address not to withdraw the entire authorized amount at once.

2. **Lack of Transparency**: Direct transfers lack clear records or events indicating the purpose of the transfer (e.g., subscription fee).

3. **Logic Separation**: Mixing business logic with payment processing leads to increased code complexity and security risks.

4. **Batch Processing Difficulties**: Processing deductions for multiple users directly requires multiple transactions, which is inefficient and costly.

5. **Management Complexity**: Maintaining information about which users have paid, when they paid, and how much requires additional storage and management.

Benefits of using the Subscribe contract:

1. **Role Separation**: Clear distinction between owner, casher, and fund recipient, enhancing security and auditability.

2. **Unified Interface**: Provides a standardized interface for subscriptions and service fees, simplifying integration and management.

3. **Transparent Records**: Records all transactions through Charge events, increasing transparency.

4. **Batch Processing**: Supports processing payments for multiple users in a single transaction, saving gas costs.

5. **Flexible Configuration**: Ability to update casher and recipient addresses to adapt to changing business needs.

6. **Security Focused**: Specifically designed for handling token deductions, following best security practices.

## How It Works

### Workflow

1. **Deployment & Setup**: Owner deploys the contract, specifying the initial casher and recipient address (toAddress).

2. **User Authorization**: Users who need to make payments call `approve(SubscribeContractAddress, allowanceAmount)` on their token contract (e.g., USDC) to authorize the Subscribe contract to spend tokens on their behalf.

3. **Payment Initiation**: When payment is due (e.g., monthly subscription), the casher calls the Subscribe contract's `charge(tokenAddress, userAddress, amount)` function.

4. **Transfer Execution**: The Subscribe contract verifies:
   - Is the caller the authorized casher?
   - Does the user have sufficient token balance? (checked implicitly by safeTransferFrom)
   - Has the user approved enough allowance for the contract? (checked implicitly by safeTransferFrom)
   
   If all checks pass, the contract transfers the specified amount from the user's address to the recipient address (toAddress).

5. **Event Logging**: After successful deduction, a `Charge` event is emitted, recording the token, source address, and amount.

6. **Batch Processing (Optional)**: The casher can prepare a list of user addresses and corresponding amounts to process multiple deductions in a single transaction using `batchCharge`.

### Key Features

- Establishes a framework for authorized deductions (Pull Payments).
- Allows centralized service providers (via the casher role) to deduct ERC20 token fees from user accounts on-demand or periodically, subject to prior user authorization.
- Directs deducted tokens straight to a designated recipient account.
- Ownership and configuration are managed by the Owner, ensuring system controllability.
- Utilizes OpenZeppelin's security libraries (Ownable, SafeERC20) for enhanced code robustness and security.

## Use Cases

This contract is ideal for decentralized applications (DApps) or services that need to manage payments, subscription fees, or service charges from numerous users. It supports:

- Subscription-based services
- Regular payment collection
- Usage-based billing
- Fee management for platform services

## Security Features

- Clear separation of roles (owner, casher, recipient)
- Utilizes SafeERC20 for secure token transfers
- Comprehensive validation checks
- Event emission for transparent transaction tracking

## Development

### Requirements

- Solidity ^0.8.13
- OpenZeppelin Contracts library

### Testing

The contract includes comprehensive test coverage using the Forge testing framework. Run tests with:

```bash
forge test
```
