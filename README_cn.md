# Pull Payment 合约

一个用于订阅和服务费场景中授权 ERC20 代币扣除的智能合约。

[English Version](README.md)

## 概述

Pull Payment 合约为需要定期收取订阅费或按需收费的服务提供解决方案，使用 ERC20 代币（如 USDC、DAI 或自定义项目代币）。它允许授权地址（"收款人"）代表指定的接收地址从预先授权的用户地址"提取"或"扣除"指定数量的代币。

## 合约地址：

| Contract Name         | Chain           | Address | Verification |
|-----------------------|------------------|---------|--------------|
| PullPaymentFactory    | Ethereum         | [0xBd315E617855990fede6024264d1Db9b8DB3E9d8](https://etherscan.io/address/0xBd315E617855990fede6024264d1Db9b8DB3E9d8) | ✅ Verified |
| PullPaymentFactory    | BSC              | [0xBd315E617855990fede6024264d1Db9b8DB3E9d8](https://bscscan.com/address/0xBd315E617855990fede6024264d1Db9b8DB3E9d8) | ✅ Verified |
| PullPaymentFactory    | Base             | [0xBd315E617855990fede6024264d1Db9b8DB3E9d8](https://basescan.org/address/0xBd315E617855990fede6024264d1Db9b8DB3E9d8) | ✅ Verified |
| PullPaymentFactory    | Polygon (POW)    | [0xBd315E617855990fede6024264d1Db9b8DB3E9d8](https://polygonscan.com/address/0xBd315E617855990fede6024264d1Db9b8DB3E9d8) | ✅ Verified |
| PullPaymentFactory    | Arbitrum One     | [0xBd315E617855990fede6024264d1Db9b8DB3E9d8](https://arbiscan.io/address/0xBd315E617855990fede6024264d1Db9b8DB3E9d8) | ✅ Verified |

## 为什么不直接使用approve机制？

虽然 ERC20 标准本身提供了 approve 机制，但直接使用它存在一些局限性和风险：

1. **额度管理困难**：直接 approve 给服务提供商意味着用户必须信任该地址不会一次性提取所有授权额度。

2. **缺乏透明度**：直接转账没有明确的记录或事件来表明转账的目的（如订阅费用）。

3. **逻辑分离**：业务逻辑与支付处理混合在一起会导致代码复杂性增加和安全风险。

4. **批量处理困难**：直接处理多个用户的扣款需要多次交易，效率低下且成本高。

5. **管理复杂性**：维护哪些用户已付款、何时付款以及金额等信息需要额外的存储和管理。

使用 Pull Payment 合约的好处：

1. **角色分离**：明确区分所有者、收款人和资金接收者，增强安全性和可审计性。

2. **统一接口**：为订阅和服务费提供标准化接口，简化集成和管理。

3. **透明记录**：通过 Charge 事件记录所有交易，提高透明度。

4. **批量处理**：支持在单个交易中处理多个用户的付款，节省 gas 费用。

5. **灵活配置**：能够更新收款人地址和接收地址，适应业务需求变化。

6. **专注安全**：专门设计用于处理代币扣款，遵循最佳安全实践。

## 多链部署

在多条链上部署相同合约时，建议遵循以下 Create2 部署模式以确保合约地址一致：

1. **使用相同的部署者地址**：在所有链上使用相同的部署者地址（最好是未发起过任何交易的新地址）以确保 nonce 相同。

2. **Factory 合约部署**：使用 Factory 合约结合 Create2 操作码进行部署，这样可以通过相同的初始化参数在不同链上生成相同的合约地址。

3. **地址一致性优势**：
   - 简化前端集成和用户体验
   - 降低跨链操作的复杂性
   - 简化合约互操作性和管理
   - 支持未来可能的跨链功能

4. **实施方法**：使用以下参数确保一致性：
   - 相同的 Factory 合约
   - 相同的 salt 值
   - 相同的初始化代码（bytecode）和构造函数参数

这种方法可以确保您的 Pull Payment 合约在以太坊、BSC、Polygon 等所有支持的链上具有相同的地址。

## 工作原理

### 流程

1. **部署与设置**：所有者部署合约，指定初始收款人和接收地址（toAddress）。

2. **用户授权**：需要付款的用户在其代币合约（如 USDC）上调用 `approve(PullPaymentContractAddress, allowanceAmount)` 来授权 Pull Payment 合约代表他们支出代币。

3. **付款启动**：当付款到期（例如月度订阅）时，收款人调用 Pull Payment 合约的 `charge(tokenAddress, userAddress, amount)` 函数。

4. **转账执行**：Pull Payment 合约验证：
   - 调用者是否为授权的收款人？
   - 用户是否有足够的代币余额？（由 safeTransferFrom 隐式检查）
   - 用户是否为合约批准了足够的额度？（由 safeTransferFrom 隐式检查）
   
   如果所有检查都通过，合约将指定数量的代币从用户地址转移到接收地址（toAddress）。

5. **事件记录**：成功扣除后，将发出 `Charge` 事件，记录代币、源地址和金额。

6. **批量处理（可选）**：收款人可以准备用户地址列表和相应金额，使用 `batchCharge` 在单个交易中处理多个扣款。

### 主要特点

- 建立授权扣款框架（拉取支付）。
- 允许集中式服务提供商（通过收款人角色）按需或定期从用户账户扣除 ERC20 代币费用，前提是用户事先授权。
- 将扣除的代币直接发送到指定的接收账户。
- 所有权和配置由所有者管理，确保系统可控性。
- 利用 OpenZeppelin 的安全库（Ownable、SafeERC20）增强代码的健壮性和安全性。

## 用例

该合约非常适合需要管理来自众多用户的支付、订阅费或服务费的去中心化应用程序（DApps）或服务。它支持：

- 基于订阅的服务
- 定期收款
- 基于使用量的计费
- 平台服务费管理

## 安全特性

- 明确的角色分离（所有者、收款人、接收者）
- 使用 SafeERC20 进行安全代币转账
- 全面的验证检查
- 事件发布，实现透明的交易跟踪

## 开发

### 要求

- Solidity ^0.8.13
- OpenZeppelin Contracts 库

### 测试

该合约使用 Forge 测试框架包含全面的测试覆盖。运行测试：

```bash
forge test
```
