# FundMe 项目使用指南和示例

## 目录
1. [快速开始](#快速开始)
2. [环境配置](#环境配置)
3. [合约部署示例](#合约部署示例)
4. [合约交互示例](#合约交互示例)
5. [常见使用场景](#常见使用场景)
6. [错误处理和调试](#错误处理和调试)
7. [最佳实践](#最佳实践)

---

## 快速开始

### 1. 项目初始化

```bash
# 克隆项目
git clone <your-repo-url>
cd Web3_tutorial

# 安装依赖（推荐使用 npm）
npm install

# 编译合约
npx hardhat compile
```

### 2. 环境变量配置

创建加密环境变量文件：

```bash
# 设置环境变量
npx env-enc set-pw
npx env-enc set SEPOLIA_URL https://sepolia.infura.io/v3/YOUR_PROJECT_ID
npx env-enc set PRIVATE_KEY your_private_key_here
npx env-enc set ETHERSCAN_API_KEY your_etherscan_api_key
npx env-enc set PRIVATE_KEY_1 second_account_private_key  # 可选
```

### 3. 一键部署和测试

```bash
# 部署到 Sepolia 测试网
npx hardhat deploy-fundme --network sepolia

# 与合约交互（替换为实际合约地址）
npx hardhat interact-fundme --addr 0x436496D5A545E4bDA95A79c7fd88984e3717f855 --network sepolia
```

---

## 环境配置

### 获取必要的 API 密钥

#### 1. Infura/Alchemy RPC 节点
```bash
# Infura (推荐)
# 访问 https://infura.io/
# 创建项目，获取 Sepolia 网络的 RPC URL
SEPOLIA_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID

# Alchemy (备选)
SEPOLIA_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

#### 2. Etherscan API 密钥
```bash
# 访问 https://etherscan.io/apis
# 注册账户并创建 API Key
ETHERSCAN_API_KEY=your_etherscan_api_key_here
```

#### 3. 测试网 ETH 获取
```bash
# Sepolia 测试网水龙头
# https://sepoliafaucet.com/
# https://faucet.sepolia.dev/
# 每个地址可以获得少量测试 ETH
```

### 网络配置验证

```javascript
// 在 hardhat.config.js 中验证配置
console.log("Sepolia URL:", process.env.SEPOLIA_URL);
console.log("Private Key exists:", !!process.env.PRIVATE_KEY);
console.log("Etherscan API Key exists:", !!process.env.ETHERSCAN_API_KEY);
```

---

## 合约部署示例

### 方式1：使用自定义任务部署

```bash
# 基本部署（锁定期 300 秒）
npx hardhat deploy-fundme --network sepolia

# 查看部署结果
# Contract deployed to: 0x436496D5A545E4bDA95A79c7fd88984e3717f855
# Waiting for 5 block confirmations...
# Contract verified on Etherscan
```

### 方式2：使用脚本部署

```bash
# 运行完整部署脚本
npx hardhat run scripts/deployFundMe.js --network sepolia
```

### 方式3：本地测试部署

```bash
# 启动本地 Hardhat 网络
npx hardhat node

# 在新终端中部署到本地网络
npx hardhat deploy-fundme --network localhost
```

### 部署参数说明

```javascript
// 在 tasks/deploy-fundme.js 中修改锁定时间
const lockTime = 300; // 300 秒 = 5 分钟

// 常用锁定时间设置
const lockTime = 60;      // 1 分钟（测试用）
const lockTime = 300;     // 5 分钟（演示用）
const lockTime = 3600;    // 1 小时
const lockTime = 86400;   // 1 天
const lockTime = 604800;  // 1 周
```

---

## 合约交互示例

### 基础交互命令

```bash
# 使用自定义任务交互
npx hardhat interact-fundme --addr CONTRACT_ADDRESS --network sepolia

# 示例输出：
# Funding with account: 0xa7d5f3A4a53bceaF99391615ACb0475f6D17d965
# Funding 0.05 ETH...
# Contract balance: 0.05 ETH
# User funded: 0.05 ETH
```

### 使用 Hardhat Console 交互

```bash
# 启动 Hardhat console
npx hardhat console --network sepolia
```

```javascript
// 在 console 中执行以下代码

// 1. 连接到已部署的合约
const contractAddress = "0x436496D5A545E4bDA95A79c7fd88984e3717f855";
const FundMe = await ethers.getContractFactory("FundMe");
const fundMe = FundMe.attach(contractAddress);

// 2. 获取账户
const [owner, user1, user2] = await ethers.getSigners();
console.log("Owner:", owner.address);

// 3. 查看合约基本信息
const contractOwner = await fundMe.owner();
const target = await fundMe.TARGET();
const minValue = await fundMe.MINIMUM_VALUE();

console.log("Contract owner:", contractOwner);
console.log("Target amount:", ethers.formatEther(target), "ETH equivalent");
console.log("Minimum value:", ethers.formatEther(minValue), "ETH equivalent");

// 4. 投资操作
const fundAmount = ethers.parseEther("0.1"); // 投资 0.1 ETH
const tx = await fundMe.connect(user1).fund({ value: fundAmount });
await tx.wait();

// 5. 查看投资结果
const balance = await ethers.provider.getBalance(contractAddress);
const userFunded = await fundMe.fundersToAmount(user1.address);

console.log("Contract balance:", ethers.formatEther(balance), "ETH");
console.log("User funded:", ethers.formatEther(userFunded), "ETH");

// 6. 获取 ETH 价格
const ethPrice = await fundMe.getChainlinkDataFeedLatestAnswer();
console.log("Current ETH price:", ethPrice.toString(), "(8 decimals)");

// 7. 转换 ETH 到 USD
const ethAmount = ethers.parseEther("1"); // 1 ETH
const usdValue = await fundMe.convertEthToUsd(ethAmount);
console.log("1 ETH =", ethers.formatEther(usdValue), "USD");
```

### 批量投资示例

```javascript
// 多个账户投资的脚本示例
async function batchFunding() {
    const signers = await ethers.getSigners();
    const contractAddress = "YOUR_CONTRACT_ADDRESS";
    const FundMe = await ethers.getContractFactory("FundMe");
    const fundMe = FundMe.attach(contractAddress);
    
    // 前5个账户各投资不同金额
    const amounts = ["0.05", "0.1", "0.15", "0.2", "0.25"];
    
    for (let i = 0; i < Math.min(5, signers.length); i++) {
        try {
            console.log(`Account ${i + 1} (${signers[i].address}) funding ${amounts[i]} ETH...`);
            
            const tx = await fundMe.connect(signers[i]).fund({
                value: ethers.parseEther(amounts[i])
            });
            await tx.wait();
            
            const funded = await fundMe.fundersToAmount(signers[i].address);
            console.log(`✓ Success! Funded: ${ethers.formatEther(funded)} ETH`);
        } catch (error) {
            console.log(`✗ Failed for account ${i + 1}:`, error.reason);
        }
    }
    
    // 显示合约总余额
    const totalBalance = await ethers.provider.getBalance(contractAddress);
    console.log(`\nTotal contract balance: ${ethers.formatEther(totalBalance)} ETH`);
}

// 运行批量投资
batchFunding();
```

---

## 常见使用场景

### 场景1：项目众筹成功

```javascript
async function successfulCrowdfunding() {
    const contractAddress = "YOUR_CONTRACT_ADDRESS";
    const FundMe = await ethers.getContractFactory("FundMe");
    const fundMe = FundMe.attach(contractAddress);
    const [owner] = await ethers.getSigners();
    
    // 1. 检查是否达到目标
    const balance = await ethers.provider.getBalance(contractAddress);
    const usdValue = await fundMe.convertEthToUsd(balance);
    const target = await fundMe.TARGET();
    
    console.log("Current USD value:", ethers.formatEther(usdValue));
    console.log("Target USD value:", ethers.formatEther(target));
    
    if (usdValue >= target) {
        console.log("✓ Target reached! Owner can withdraw funds.");
        
        // 2. 等待锁定期结束
        // 注意：实际使用中需要等待真实时间
        
        // 3. 项目方提取资金
        try {
            const tx = await fundMe.connect(owner).getFund();
            await tx.wait();
            console.log("✓ Funds successfully withdrawn by owner!");
        } catch (error) {
            console.log("✗ Withdrawal failed:", error.reason);
        }
    } else {
        console.log("✗ Target not reached yet.");
    }
}
```

### 场景2：项目众筹失败，投资者退款

```javascript
async function failedCrowdfundingRefund() {
    const contractAddress = "YOUR_CONTRACT_ADDRESS";
    const FundMe = await ethers.getContractFactory("FundMe");
    const fundMe = FundMe.attach(contractAddress);
    const signers = await ethers.getSigners();
    
    // 1. 检查是否未达到目标且锁定期已结束
    const balance = await ethers.provider.getBalance(contractAddress);
    const usdValue = await fundMe.convertEthToUsd(balance);
    const target = await fundMe.TARGET();
    
    if (usdValue < target) {
        console.log("Target not reached. Investors can request refunds.");
        
        // 2. 每个投资者申请退款
        for (let i = 1; i < signers.length; i++) {
            const userFunded = await fundMe.fundersToAmount(signers[i].address);
            
            if (userFunded > 0) {
                try {
                    console.log(`Refunding ${ethers.formatEther(userFunded)} ETH to ${signers[i].address}...`);
                    
                    const tx = await fundMe.connect(signers[i]).refund();
                    await tx.wait();
                    
                    console.log("✓ Refund successful!");
                } catch (error) {
                    console.log("✗ Refund failed:", error.reason);
                }
            }
        }
    }
}
```

### 场景3：实时监控合约状态

```javascript
async function monitorContract() {
    const contractAddress = "YOUR_CONTRACT_ADDRESS";
    const FundMe = await ethers.getContractFactory("FundMe");
    const fundMe = FundMe.attach(contractAddress);
    
    // 监控函数
    async function checkStatus() {
        console.log("\n=== Contract Status ===");
        
        // 基本信息
        const balance = await ethers.provider.getBalance(contractAddress);
        const usdValue = await fundMe.convertEthToUsd(balance);
        const target = await fundMe.TARGET();
        const owner = await fundMe.owner();
        
        console.log("Contract Balance:", ethers.formatEther(balance), "ETH");
        console.log("USD Value:", ethers.formatEther(usdValue), "USD");
        console.log("Target:", ethers.formatEther(target), "USD");
        console.log("Progress:", ((usdValue * 100n) / target).toString() + "%");
        console.log("Owner:", owner);
        
        // 时间信息
        const currentTime = Math.floor(Date.now() / 1000);
        const deploymentTime = await fundMe.deploymentTimestamp();
        const lockTime = await fundMe.lockTime();
        const endTime = deploymentTime + lockTime;
        
        console.log("Current Time:", new Date(currentTime * 1000).toLocaleString());
        console.log("End Time:", new Date(Number(endTime) * 1000).toLocaleString());
        console.log("Time Remaining:", Math.max(0, Number(endTime) - currentTime), "seconds");
        
        // 状态判断
        if (currentTime >= endTime) {
            if (usdValue >= target) {
                console.log("🎉 SUCCESS: Target reached! Owner can withdraw.");
            } else {
                console.log("💔 FAILED: Target not reached. Investors can refund.");
            }
        } else {
            console.log("⏳ IN PROGRESS: Funding window still open.");
        }
    }
    
    // 每30秒检查一次
    setInterval(checkStatus, 30000);
    checkStatus(); // 立即执行一次
}

// 启动监控
monitorContract();
```

---

## 错误处理和调试

### 常见错误及解决方案

#### 1. 部署相关错误

```bash
# 错误：insufficient funds
# 原因：账户余额不足支付 gas 费
# 解决：从水龙头获取更多测试 ETH

# 错误：nonce too high
# 原因：交易 nonce 不同步
# 解决：重置 MetaMask 账户或等待网络同步

# 错误：replacement transaction underpriced
# 原因：gas 价格设置过低
# 解决：增加 gas 价格或等待网络拥堵缓解
```

#### 2. 合约交互错误

```javascript
// 错误处理示例
async function safeContractInteraction() {
    try {
        const tx = await fundMe.fund({ value: ethers.parseEther("0.05") });
        await tx.wait();
        console.log("Transaction successful!");
    } catch (error) {
        // 解析具体错误
        if (error.reason) {
            switch (error.reason) {
                case "Send more ETH":
                    console.log("❌ 投资金额不足100美元等值");
                    break;
                case "window is closed":
                    console.log("❌ 投资窗口已关闭");
                    break;
                case "Target is not reached":
                    console.log("❌ 未达到目标金额，无法提取");
                    break;
                case "window is not closed":
                    console.log("❌ 锁定期未结束");
                    break;
                default:
                    console.log("❌ 合约错误:", error.reason);
            }
        } else if (error.code === 'INSUFFICIENT_FUNDS') {
            console.log("❌ 账户余额不足");
        } else {
            console.log("❌ 未知错误:", error.message);
        }
    }
}
```

#### 3. 网络连接问题

```javascript
// 网络连接检查
async function checkNetworkConnection() {
    try {
        const network = await ethers.provider.getNetwork();
        console.log("Connected to network:", network.name, "Chain ID:", network.chainId);
        
        const blockNumber = await ethers.provider.getBlockNumber();
        console.log("Current block number:", blockNumber);
        
        return true;
    } catch (error) {
        console.log("❌ Network connection failed:", error.message);
        return false;
    }
}
```

### 调试技巧

#### 1. 使用 console.log 调试

```javascript
// 在合约中添加事件用于调试
contract FundMe {
    event FundReceived(address indexed funder, uint256 amount, uint256 usdValue);
    
    function fund() external payable {
        uint256 usdValue = convertEthToUsd(msg.value);
        emit FundReceived(msg.sender, msg.value, usdValue);
        // ... 其他逻辑
    }
}

// 在脚本中监听事件
fundMe.on("FundReceived", (funder, amount, usdValue) => {
    console.log(`💰 Received ${ethers.formatEther(amount)} ETH (${ethers.formatEther(usdValue)} USD) from ${funder}`);
});
```

#### 2. 交易详情查看

```javascript
async function analyzeTransaction(txHash) {
    const tx = await ethers.provider.getTransaction(txHash);
    const receipt = await ethers.provider.getTransactionReceipt(txHash);
    
    console.log("Transaction Details:");
    console.log("- Hash:", tx.hash);
    console.log("- From:", tx.from);
    console.log("- To:", tx.to);
    console.log("- Value:", ethers.formatEther(tx.value), "ETH");
    console.log("- Gas Limit:", tx.gasLimit.toString());
    console.log("- Gas Price:", ethers.formatUnits(tx.gasPrice, "gwei"), "gwei");
    console.log("- Status:", receipt.status === 1 ? "Success" : "Failed");
    console.log("- Gas Used:", receipt.gasUsed.toString());
}
```

---

## 最佳实践

### 1. 安全实践

```javascript
// ✅ 好的做法
// 1. 始终验证输入参数
require(msg.value > 0, "Amount must be greater than 0");
require(newOwner != address(0), "Invalid address");

// 2. 使用 checks-effects-interactions 模式
function withdraw() external {
    // Checks
    require(msg.sender == owner, "Not owner");
    require(address(this).balance > 0, "No funds");
    
    // Effects
    uint256 amount = address(this).balance;
    fundersToAmount[msg.sender] = 0;
    
    // Interactions
    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success, "Transfer failed");
}

// 3. 防止重入攻击
bool private locked;
modifier noReentrant() {
    require(!locked, "Reentrant call");
    locked = true;
    _;
    locked = false;
}
```

### 2. Gas 优化

```javascript
// ✅ Gas 优化技巧

// 1. 使用 immutable 和 constant
uint256 public constant MINIMUM_VALUE = 100 * 10**18;
address public immutable owner;

// 2. 批量操作
function batchRefund(address[] calldata funders) external {
    for (uint i = 0; i < funders.length; i++) {
        // 批量退款逻辑
    }
}

// 3. 合理使用数据类型
uint128 public smallNumber;  // 而不是 uint256（如果数值范围允许）
```

### 3. 测试策略

```javascript
// 完整的测试用例示例
describe("FundMe Contract", function() {
    let fundMe, owner, user1, user2;
    
    beforeEach(async function() {
        [owner, user1, user2] = await ethers.getSigners();
        const FundMe = await ethers.getContractFactory("FundMe");
        fundMe = await FundMe.deploy(300); // 5分钟锁定期
    });
    
    describe("Funding", function() {
        it("Should accept funding above minimum", async function() {
            await expect(
                fundMe.connect(user1).fund({ value: ethers.parseEther("0.1") })
            ).to.not.be.reverted;
        });
        
        it("Should reject funding below minimum", async function() {
            await expect(
                fundMe.connect(user1).fund({ value: ethers.parseEther("0.001") })
            ).to.be.revertedWith("Send more ETH");
        });
    });
    
    describe("Withdrawal", function() {
        it("Should allow owner to withdraw after target reached", async function() {
            // 设置测试场景...
        });
    });
});
```

### 4. 部署清单

```bash
# 部署前检查清单
□ 环境变量已正确设置
□ 私钥对应的账户有足够的测试 ETH
□ 网络配置正确（chainId, RPC URL）
□ 合约参数已确认（lockTime, 目标金额等）
□ Etherscan API Key 有效
□ 代码已通过测试
□ 已在本地网络测试过完整流程

# 部署后验证清单
□ 合约地址已记录
□ 合约在 Etherscan 上已验证
□ 基本功能测试通过
□ 所有权设置正确
□ 时间参数设置正确
```

### 5. 监控和维护

```javascript
// 设置合约监控
async function setupMonitoring() {
    // 监听所有相关事件
    fundMe.on("*", (event) => {
        console.log("Contract Event:", event);
    });
    
    // 定期健康检查
    setInterval(async () => {
        const balance = await ethers.provider.getBalance(fundMe.target);
        const blockNumber = await ethers.provider.getBlockNumber();
        
        console.log(`Health Check - Block: ${blockNumber}, Balance: ${ethers.formatEther(balance)} ETH`);
    }, 60000); // 每分钟检查一次
}
```

---

## 总结

这个使用指南涵盖了 FundMe 项目的完整使用流程，从环境配置到合约部署，从基础交互到高级调试。通过这些示例和最佳实践，你可以：

1. **快速上手** - 按照快速开始部分即可运行项目
2. **深入理解** - 通过详细示例了解每个功能
3. **安全开发** - 遵循最佳实践避免常见陷阱
4. **有效调试** - 使用提供的调试技巧快速定位问题

记住始终在测试网络上进行充分测试，确保理解每个功能后再考虑主网部署。
