// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// 导入 Chainlink 价格预言机接口
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @title FundMe - 众筹合约
 * @dev 这是一个基于以太坊的众筹智能合约，具有以下功能：
 * 1. 创建一个收款函数 - 允许用户向合约发送 ETH
 * 2. 记录投资人并且查看 - 跟踪每个地址的投资金额
 * 3. 在锁定期内，达到目标值, 生产商可以提款 - 项目方可以提取资金
 * 4. 在锁定期内，没有达到目标值, 投资人在锁定期以后退款 - 投资者可以退款
 * 
 * @notice 本合约使用 Chainlink 价格预言机获取 ETH/USD 实时汇率
 */
contract FundMe {
    
    // ========== 状态变量 ==========
    
    /**
     * @dev 记录每个投资者地址对应的投资金额（以 wei 为单位）
     * @notice 这是一个公开的映射，任何人都可以查询特定地址的投资金额
     */
    mapping (address => uint256) public fundersToAmount;

    /**
     * @dev 最小投资金额，以美元计价（100 USD，18位小数）
     * @notice 投资者必须至少投资 100 美元等值的 ETH
     */
    uint256 MINIMUM_VALUE = 100 * 10 ** 18;  // 100 USD (18 decimals)

    /**
     * @dev Chainlink 价格预言机接口实例
     * @notice 用于获取 ETH/USD 实时汇率
     */
    AggregatorV3Interface internal dataFeed;

    /**
     * @dev 众筹目标金额，以美元计价（1000 USD，18位小数）
     * @notice 只有达到这个目标，项目方才能提取资金
     */
    uint256 constant TARGET = 1000 * 10 ** 18; // 1000 USD (18 decimals)

    /**
     * @dev 合约拥有者地址（项目方）
     * @notice 只有拥有者可以提取资金和转移所有权
     */
    address public owner;

    /**
     * @dev 合约部署时的时间戳
     * @notice 用于计算锁定期是否结束
     */
    uint256 deploymentTimestamp;
    
    /**
     * @dev 锁定时间（秒）
     * @notice 在此时间内，投资者可以投资，时间结束后进入结算阶段
     */
    uint256 lockTime;

    /**
     * @dev ERC20 代币合约地址
     * @notice 用于与 ERC20 代币集成的功能
     */
    address erc20Addr;

    /**
     * @dev 标记项目方是否已成功提取资金
     * @notice 防止重复提取
     */
    bool public getFundSuccess = false;
    

    // ========== 构造函数 ==========
    
    /**
     * @dev 构造函数 - 初始化合约
     * @param _lockTime 锁定时间（秒），在此期间投资者可以投资
     * @notice 部署时设置项目的锁定期，例如 300 秒 = 5 分钟
     */
    constructor(uint256 _lockTime) {
        // 初始化 Chainlink ETH/USD 价格预言机 (Sepolia 测试网地址)
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        
        // 设置合约部署者为拥有者
        owner = msg.sender;
        
        // 记录部署时间戳
        deploymentTimestamp = block.timestamp;
        
        // 设置锁定时间
        lockTime = _lockTime;
    }

    // ========== 核心功能函数 ==========

    /**
     * @dev 投资函数 - 允许用户向合约发送 ETH 进行投资
     * @notice 投资者需要发送至少 100 美元等值的 ETH，且必须在锁定期内
     * 
     * 要求：
     * 1. 发送的 ETH 价值必须 >= 100 USD
     * 2. 必须在锁定期内（当前时间 < 部署时间 + 锁定时间）
     * 
     * 效果：
     * - 记录投资者地址和投资金额
     * - ETH 存储在合约中
     */
    function fund () external payable {
       require(convertEthToUsd(msg.value) >= MINIMUM_VALUE, "Send more ETH");
       require(block.timestamp < deploymentTimestamp + lockTime, "window is closed");
       fundersToAmount[msg.sender] = msg.value;
    }

    // ========== 价格预言机相关函数 ==========

    /**
     * @dev 获取 Chainlink 价格预言机的最新 ETH/USD 价格
     * @return int256 ETH 价格（美元，8位小数）
     * @notice 例如：返回 200000000000 表示 1 ETH = $2000.00000000
     */
     function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundId */,        // 轮次ID（未使用）
            int256 answer,              // 价格答案
            /*uint256 startedAt*/,      // 开始时间（未使用）
            /*uint256 updatedAt*/,      // 更新时间（未使用）
            /*uint80 answeredInRound*/  // 回答轮次（未使用）
        ) = dataFeed.latestRoundData();
        return answer;
    }

    /**
     * @dev 将 ETH 数量转换为对应的 USD 价值
     * @param ethAmount ETH 数量（以 wei 为单位）
     * @return uint256 对应的 USD 价值（18位小数）
     * 
     * 计算逻辑：
     * 1. 获取 ETH 价格（8位小数）
     * 2. ETH数量 × ETH价格 ÷ 10^8 = USD价值（18位小数）
     */
    function convertEthToUsd(uint256 ethAmount) internal view returns(uint256) {
        uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer());
        return ethAmount * ethPrice / (10 ** 8);
    }

    // ========== 管理功能函数 ==========

    /**
     * @dev 转移合约所有权
     * @param newOwner 新拥有者地址
     * @notice 只有当前拥有者可以调用此函数
     */
    function transferOwnership(address newOwner) public onlyOwner{
        owner = newOwner;
    }

    /**
     * @dev 项目方提取资金函数
     * @notice 只有在锁定期结束且达到目标金额时，项目方才能提取所有资金
     * 
     * 要求：
     * 1. 锁定期必须已结束
     * 2. 只有合约拥有者可以调用
     * 3. 合约余额的美元价值必须 >= 1000 USD
     * 
     * 效果：
     * - 将合约中的所有 ETH 转给项目方
     * - 清零项目方的投资记录
     * - 设置成功提取标志
     */
    function getFund() external windowClosed onlyOwner{
        require(convertEthToUsd(address(this).balance) >= TARGET, "Target is not reached");

        // ========== ETH 转账的三种方式对比 ==========
        
        // 方式1: transfer - 转账失败时自动回滚，但 gas 限制为 2300
        // payable(msg.sender).transfer(address(this).balance);
        
        // 方式2: send - 转账失败时返回 false，需要手动检查，gas 限制为 2300
        // bool success = payable(msg.sender).send(address(this).balance);
        // require(success, "tx failed");

        // 方式3: call - 最推荐的方式，可以自定义 gas，返回成功状态
        bool success;
        (success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "transfer tx failed");
        
        // 清零项目方投资记录，防止重复提取
        fundersToAmount[msg.sender] = 0;
        
        // 设置成功标志
        getFundSuccess = true;
    }

    /**
     * @dev 投资者退款函数
     * @notice 当锁定期结束且未达到目标金额时，投资者可以申请退款
     * 
     * 要求：
     * 1. 锁定期必须已结束
     * 2. 合约余额的美元价值必须 < 1000 USD（未达到目标）
     * 3. 调用者必须有投资记录
     * 
     * 效果：
     * - 将投资者的投资金额退还
     * - 清零投资者的投资记录
     */
    function refund() external windowClosed{
        require(convertEthToUsd(address(this).balance) < TARGET, "Target is reached");
        require(fundersToAmount[msg.sender] != 0, "there is no fund for you");
        
        // 使用 call 方式转账（最安全）
        bool success;
        (success, ) = payable(msg.sender).call{value: fundersToAmount[msg.sender]}("");
        require(success, "transfer tx failed");
        
        // 清零投资记录，防止重复退款
        fundersToAmount[msg.sender] = 0;
    }

    // ========== ERC20 集成功能 ==========

    /**
     * @dev 设置投资者的投资金额（供 ERC20 代币合约调用）
     * @param funder 投资者地址
     * @param amountToUpdate 要更新的金额
     * @notice 只有授权的 ERC20 合约可以调用此函数
     */
    function setFunderToAmount(address funder, uint256 amountToUpdate) external {
        require(msg.sender == erc20Addr, "you do not have permission to call this function");
        fundersToAmount[funder] = amountToUpdate;
    }

    /**
     * @dev 设置 ERC20 代币合约地址
     * @param _erc20Addr ERC20 代币合约地址
     * @notice 只有合约拥有者可以设置
     */
    function setErc20Addr(address _erc20Addr) public onlyOwner{
        erc20Addr = _erc20Addr;
    }

    // ========== 修饰器 ==========

    /**
     * @dev 检查锁定期是否已结束的修饰器
     * @notice 确保当前时间 >= 部署时间 + 锁定时间
     */
    modifier windowClosed() {
        require(block.timestamp >= deploymentTimestamp + lockTime, "window is not closed");
        _;
    }

    /**
     * @dev 检查调用者是否为合约拥有者的修饰器
     * @notice 限制某些敏感功能只能由拥有者调用
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "this function can only be called by owner");
        _;
    }


}