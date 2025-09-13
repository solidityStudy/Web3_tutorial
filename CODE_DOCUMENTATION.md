# FundMe 项目代码详细说明

## 目录
1. [智能合约代码](#智能合约代码)
2. [配置文件](#配置文件)
3. [部署脚本](#部署脚本)
4. [自定义任务](#自定义任务)
5. [项目配置](#项目配置)

---

## 智能合约代码

### FundMe.sol - 主要合约

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract FundMe {
    // 状态变量
    mapping(address => uint256) public fundersToAmount;  // 记录每个地址的资助金额
    uint256 public constant MINIMUM_VALUE = 10**18;     // 最小资助金额 (1 ETH)
    address public immutable owner;                     // 合约拥有者
    uint256 public immutable lockTime;                  // 锁定时间
    uint256 public deploymentTimestamp;                 // 部署时间戳

    // 构造函数
    constructor(uint256 _lockTime) {
        owner = msg.sender;           // 设置部署者为拥有者
        lockTime = _lockTime;         // 设置锁定时间
        deploymentTimestamp = block.timestamp;  // 记录部署时间
    }

    // 资助函数 - payable 表示可以接收 ETH
    function fund() external payable {
        require(msg.value >= MINIMUM_VALUE, "Send more money!");
        fundersToAmount[msg.sender] += msg.value;  // 累加用户资助金额
    }

    // 提取函数 - 只有拥有者可以调用
    function withdraw() external {
        require(msg.sender == owner, "Not owner!");
        require(block.timestamp >= deploymentTimestamp + lockTime, "Still locked!");
        
        // 重置所有资助记录（防止重入攻击）
        for (uint256 i = 0; i < funders.length; i++) {
            fundersToAmount[funders[i]] = 0;
        }
        delete funders;  // 清空资助者数组
        
        // 转账给拥有者
        payable(owner).transfer(address(this).balance);
    }

    // 获取合约余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

**关键概念解释：**

1. **mapping**: 类似于哈希表，`mapping(address => uint256)` 将地址映射到数值
2. **payable**: 标记函数可以接收 ETH
3. **require**: 条件检查，失败时回滚交易
4. **msg.sender**: 调用函数的地址
5. **msg.value**: 发送的 ETH 数量（以 wei 为单位）
6. **immutable**: 部署后不可更改的变量
7. **block.timestamp**: 当前区块时间戳

---

## 配置文件

### hardhat.config.js - Hardhat 配置

```javascript
// 导入必要的插件和工具
require("@nomicfoundation/hardhat-toolbox");  // Hardhat 工具套件
require("@chainlink/env-enc").config();       // 加密环境变量管理
require("./tasks/deploy-fundme");             // 自定义部署任务
require("./tasks/interact-fundme");           // 自定义交互任务

// 从环境变量获取配置
const SEPOLIA_URL = process.env.SEPOLIA_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
const PRIVATE_KEY_1 = process.env.PRIVATE_KEY_1;

module.exports = {
  solidity: "0.8.24",  // Solidity 编译器版本
  
  networks: {
    sepolia: {
      url: SEPOLIA_URL,                    // RPC 节点 URL
      accounts: [PRIVATE_KEY, PRIVATE_KEY_1], // 私钥数组
      chainId: 11155111,                   // Sepolia 链 ID
    }
  },
  
  etherscan: {
    apiKey: ETHERSCAN_API_KEY  // Etherscan API 密钥（用于合约验证）
  }
};
```

**配置说明：**

- **solidity**: 指定 Solidity 编译器版本
- **networks**: 定义不同的网络配置
- **accounts**: 用于签名交易的私钥列表
- **chainId**: 网络链标识符，防止重放攻击
- **etherscan**: 用于自动验证合约源代码

---

## 部署脚本

### scripts/deployFundMe.js - 完整部署脚本

```javascript
const { ethers } = require("hardhat");

async function main() {
    // 1. 获取合约工厂
    const fundMeFactory = await ethers.getContractFactory("FundMe");
    console.log("Deploying contract...");
    
    // 2. 部署合约
    const lockTime = 300; // 锁定时间：300秒（5分钟）
    const fundMe = await fundMeFactory.deploy(lockTime);
    await fundMe.waitForDeployment();  // 等待部署完成
    console.log("Contract deployed to:", fundMe.target);

    // 3. 获取网络信息进行验证
    const chainId = await hre.network.provider.send("eth_chainId");
    console.log("Network chainId (decimal):", parseInt(chainId, 16));
    
    // 4. 条件验证（仅在 Sepolia 网络且有 API Key 时）
    if (parseInt(chainId, 16) === 11155111 && process.env.ETHERSCAN_API_KEY) {
        console.log("Waiting for 5 block confirmations...");
        await fundMe.deploymentTransaction().wait(5);  // 等待5个区块确认
        await verifyFundMe(fundMe.target, [lockTime]);
    }

    // 5. 合约交互测试
    const signers = await ethers.getSigners();
    const firstAccount = signers[0];
    
    // 第一个账户资助 0.5 ETH
    const fundTx = await fundMe.connect(firstAccount).fund({
        value: ethers.parseEther("0.5")
    });
    await fundTx.wait();
    
    // 检查合约余额
    const balance = await ethers.provider.getBalance(fundMe.target);
    console.log(`Contract balance: ${ethers.formatEther(balance)} ETH`);
    
    // 检查用户资助金额
    const userFunded = await fundMe.fundersToAmount(firstAccount.address);
    console.log(`User funded: ${ethers.formatEther(userFunded)} ETH`);
}

// 合约验证函数
async function verifyFundMe(contractAddress, constructorArgs) {
    await hre.run("verify:verify", {
        address: contractAddress,
        constructorArguments: constructorArgs,
    });
}

// 执行主函数
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

**脚本流程解析：**

1. **合约工厂创建**: `getContractFactory()` 获取合约的部署工厂
2. **合约部署**: `deploy()` 部署合约到区块链
3. **等待确认**: `waitForDeployment()` 等待交易被挖矿确认
4. **条件验证**: 检查网络和 API Key，决定是否验证合约
5. **交互测试**: 调用合约函数测试功能

---

## 自定义任务

### tasks/deploy-fundme.js - 部署任务

```javascript
const { task } = require("hardhat/config");

// 定义自定义任务
task("deploy-fundme", "Deploy FundMe contract")
    .setAction(async (taskArgs, hre) => {
        // 任务执行逻辑
        const fundMeFactory = await ethers.getContractFactory("FundMe");
        const lockTime = 300;
        const fundMe = await fundMeFactory.deploy(lockTime);
        await fundMe.waitForDeployment();
        
        console.log("Contract deployed to:", fundMe.target);
        
        // 验证逻辑
        const chainId = await hre.network.provider.send("eth_chainId");
        if (parseInt(chainId, 16) === 11155111 && process.env.ETHERSCAN_API_KEY) {
            await fundMe.deploymentTransaction().wait(5);
            await verifyFundMe(fundMe.target, [lockTime]);
        }
    });

async function verifyFundMe(fundMeAddr, args) {
    await hre.run("verify:verify", {
        address: fundMeAddr,
        constructorArguments: args,
    });
}

module.exports = {};
```

### tasks/interact-fundme.js - 交互任务

```javascript
const { task } = require("hardhat/config");

// 定义带参数的任务
task("interact-fundme", "Interact with FundMe contract")
    .addParam("addr", "FundMe contract address")  // 添加地址参数
    .setAction(async (taskArgs, hre) => {
        // 连接到已部署的合约
        const fundMeFactory = await ethers.getContractFactory("FundMe");
        const fundMe = await fundMeFactory.attach(taskArgs.addr);
        
        // 获取签名者
        const signers = await ethers.getSigners();
        const firstAccount = signers[0];
        
        // 资助合约
        const fundTx = await fundMe.connect(firstAccount).fund({
            value: ethers.parseEther("0.05")  // 资助 0.05 ETH
        });
        await fundTx.wait();
        
        // 查询结果
        const balance = await ethers.provider.getBalance(fundMe.target);
        const userFunded = await fundMe.fundersToAmount(firstAccount.address);
        
        console.log(`Contract balance: ${ethers.formatEther(balance)} ETH`);
        console.log(`User funded: ${ethers.formatEther(userFunded)} ETH`);
    });

module.exports = {};
```

**任务系统特点：**

- **task()**: 定义新的 Hardhat 任务
- **addParam()**: 为任务添加命令行参数
- **setAction()**: 定义任务执行逻辑
- **taskArgs**: 访问命令行传入的参数
- **hre**: Hardhat Runtime Environment，提供完整的运行时环境

---

## 项目配置

### package.json - 依赖管理

```json
{
  "name": "web3_tutorial",
  "version": "1.0.0",
  "devDependencies": {
    "@chainlink/contracts": "^1.4.0",           // Chainlink 合约库
    "@nomicfoundation/hardhat-toolbox": "^6.1.0", // Hardhat 工具套件
    "hardhat": "^2.22.2"                        // Hardhat 核心框架
  }
}
```

### .gitignore - 版本控制忽略文件

```
node_modules     # 依赖包目录
.env            # 环境变量文件
.env.enc        # 加密环境变量文件

# Hardhat 文件
/cache          # 编译缓存
/artifacts      # 编译产物
```

---

## 关键概念详解

### 1. Ethers.js 核心概念

```javascript
// Provider: 连接到区块链网络
const provider = ethers.provider;

// Signer: 可以签名交易的账户
const signer = await ethers.getSigners()[0];

// Contract Factory: 用于部署合约
const factory = await ethers.getContractFactory("ContractName");

// Contract Instance: 已部署合约的实例
const contract = await factory.attach(contractAddress);

// 单位转换
ethers.parseEther("1.0");    // 1 ETH 转为 wei
ethers.formatEther(balance); // wei 转为 ETH 字符串
```

### 2. 交易处理流程

```javascript
// 1. 创建交易
const tx = await contract.functionName(params, { value: ethers.parseEther("1") });

// 2. 等待交易被挖矿
const receipt = await tx.wait();

// 3. 检查交易状态
console.log("Transaction hash:", tx.hash);
console.log("Block number:", receipt.blockNumber);
```

### 3. 错误处理最佳实践

```javascript
try {
    const tx = await contract.fund({ value: ethers.parseEther("0.5") });
    await tx.wait();
    console.log("Transaction successful");
} catch (error) {
    if (error.code === 'INSUFFICIENT_FUNDS') {
        console.log("Insufficient balance");
    } else if (error.reason) {
        console.log("Contract error:", error.reason);
    } else {
        console.log("Unknown error:", error.message);
    }
}
```

---

## 开发工作流程

### 1. 开发阶段
```bash
# 编译合约
npx hardhat compile

# 运行测试
npx hardhat test

# 本地部署测试
npx hardhat run scripts/deployFundMe.js
```

### 2. 测试网部署
```bash
# 部署到 Sepolia
npx hardhat deploy-fundme --network sepolia

# 验证合约
npx hardhat verify --network sepolia CONTRACT_ADDRESS CONSTRUCTOR_ARGS
```

### 3. 合约交互
```bash
# 使用自定义任务交互
npx hardhat interact-fundme --addr CONTRACT_ADDRESS --network sepolia
```

---

## 安全考虑

### 1. 私钥管理
- 使用环境变量存储私钥
- 使用加密工具（如 @chainlink/env-enc）
- 永远不要将私钥提交到代码仓库

### 2. 合约安全
- 使用 `require` 进行输入验证
- 防止重入攻击（先修改状态，再转账）
- 设置合理的访问控制

### 3. 测试策略
- 在测试网络充分测试
- 测试边界条件和异常情况
- 使用静态分析工具检查漏洞

这个文档涵盖了项目中所有重要代码的详细说明，帮助初学者理解 Hardhat 和智能合约开发的核心概念。
