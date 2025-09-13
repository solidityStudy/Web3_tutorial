# FundMe 智能合约项目

这是一个基于 Hardhat 的 Web3 教学项目，实现了一个资金募集智能合约 (FundMe)。该项目展示了智能合约的开发、部署、验证和交互的完整流程。

## 项目概述

FundMe 合约允许用户向合约地址转入 ETH，并记录每个用户的资助金额。合约包含锁定时间机制，在锁定期内资金不能被提取。

### 主要功能
- 💰 **资金募集**: 用户可以向合约转入 ETH
- 📊 **资金追踪**: 记录每个地址的资助金额
- 🔒 **时间锁定**: 设置资金锁定期，防止提前提取
- 🔍 **合约验证**: 自动在 Etherscan 上验证合约源代码
- 🛠️ **多账户测试**: 支持多个账户的交互测试

## 项目结构

```
Web3_tutorial/
├── contracts/                 # 智能合约源代码
│   ├── FundMe.sol             # 主要的资金募集合约
│   └── Lock.sol               # 示例锁定合约
├── scripts/                   # 部署和交互脚本
│   └── deployFundMe.js        # FundMe合约部署脚本
├── tasks/                     # Hardhat 自定义任务
│   ├── deploy-fundme.js       # 部署任务
│   ├── interact-fundme.js     # 交互任务
│   └── index.js               # 任务索引文件
├── test/                      # 测试文件
├── ignition/                  # Hardhat Ignition 部署模块
├── artifacts/                 # 编译产物
├── cache/                     # 缓存文件
├── hardhat.config.js          # Hardhat 配置文件
├── package.json               # 项目依赖配置
├── .env.enc                   # 加密的环境变量
└── .gitignore                 # Git 忽略文件
```

## 环境要求

- Node.js >= 16.0.0
- npm 或 pnpm
- Git

## 快速开始

### 1. 安装依赖

```bash
npm install
# 或
pnpm install
```

### 2. 环境配置

项目使用 `@chainlink/env-enc` 来管理加密的环境变量：

```bash
# 设置环境变量
npx env-enc set-pw  # 设置密码
npx env-enc set SEPOLIA_URL your_sepolia_rpc_url
npx env-enc set PRIVATE_KEY your_private_key
npx env-enc set PRIVATE_KEY_1 your_second_private_key  # 可选
npx env-enc set ETHERSCAN_API_KEY your_etherscan_api_key
```

### 3. 编译合约

```bash
npx hardhat compile
```

### 4. 部署合约

#### 方法1: 使用脚本部署
```bash
# 部署到本地网络
npx hardhat run scripts/deployFundMe.js

# 部署到 Sepolia 测试网
npx hardhat run scripts/deployFundMe.js --network sepolia
```

#### 方法2: 使用自定义任务部署
```bash
# 部署到 Sepolia 测试网
npx hardhat deploy-fundme --network sepolia
```

### 5. 与合约交互

```bash
# 与已部署的合约交互
npx hardhat interact-fundme --addr 0x合约地址 --network sepolia
```

## 可用命令

```bash
# 查看所有可用任务
npx hardhat help

# 编译合约
npx hardhat compile

# 运行测试
npx hardhat test

# 部署 FundMe 合约
npx hardhat deploy-fundme --network sepolia

# 与 FundMe 合约交互
npx hardhat interact-fundme --addr CONTRACT_ADDRESS --network sepolia

# 验证合约
npx hardhat verify --network sepolia CONTRACT_ADDRESS CONSTRUCTOR_ARGS

# 启动本地节点
npx hardhat node
```

## 网络配置

项目配置了以下网络：

- **Hardhat Network**: 本地开发网络（默认）
- **Sepolia Testnet**: 以太坊测试网络

## 技术栈

- **Hardhat**: 以太坊开发环境
- **Solidity**: 智能合约编程语言
- **Ethers.js**: 以太坊 JavaScript 库
- **Chainlink**: 预言机和工具库
- **Etherscan**: 合约验证服务

## 学习要点

### 1. 智能合约开发
- Solidity 语法和最佳实践
- 合约状态管理
- 事件日志记录
- 访问控制和安全性

### 2. Hardhat 框架
- 项目结构和配置
- 编译和部署流程
- 自定义任务开发
- 网络配置管理

### 3. Web3 交互
- 合约实例化和连接
- 交易发送和确认
- 事件监听和查询
- 多账户管理

### 4. 开发工具链
- 环境变量管理
- 合约验证流程
- 测试网络使用
- 调试和错误处理

## 注意事项

⚠️ **安全提醒**:
- 永远不要将私钥提交到代码仓库
- 使用测试网络进行开发和测试
- 在主网部署前进行充分测试

📝 **开发建议**:
- 保持合约代码简洁和可读
- 添加详细的注释和文档
- 使用版本控制管理代码变更
- 定期备份重要数据

## 故障排除

### 常见问题

1. **pnpm install 卡住**
   ```bash
   # 使用 npm 替代
   npm install --registry=https://registry.npmmirror.com
   ```

2. **合约验证失败**
   ```bash
   # 等待更多区块确认后重试
   npx hardhat verify --network sepolia CONTRACT_ADDRESS CONSTRUCTOR_ARGS
   ```

3. **账户余额不足**
   - 确保账户有足够的测试 ETH
   - 从水龙头获取测试代币

## 贡献指南

欢迎提交 Issue 和 Pull Request 来改进这个项目！

## 许可证

本项目采用 ISC 许可证。
