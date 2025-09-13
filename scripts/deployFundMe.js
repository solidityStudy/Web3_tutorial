// import ethers.js
// create main function
    //init 2 accounts
    // fund contract with first account
    // check balance of contract
    // fund contract with second account
    // check balance of contract
    // check mapping fundersToAmount
// execute main function
const { ethers } = require("hardhat");

async function main() {
    // Create factory
    const fundMeFactory = await ethers.getContractFactory("FundMe");
    console.log("Deploying contract...");
    // Deploy contract with lock time (e.g., 1 day = 86400 seconds)
    const lockTime = 300; // 1 day in seconds, adjust as needed
    const fundMe = await fundMeFactory.deploy(lockTime);
    await fundMe.waitForDeployment();
    console.log("Contract has been deployed successfully, contract address is: " + fundMe.target);

    // verify fundme
    const chainId = await hre.network.provider.send("eth_chainId");
    console.log("Network chainId:", chainId);
    console.log("Network chainId (decimal):", parseInt(chainId, 16));
    console.log("ETHERSCAN_API_KEY exists:", !!process.env.ETHERSCAN_API_KEY);
    console.log("Network name:", hre.network.name);
    
    if (parseInt(chainId, 16) === 11155111 && process.env.ETHERSCAN_API_KEY) {
        console.log("Waiting for 5 block confirmations...");
        await fundMe.deploymentTransaction().wait(5);
        await verifyFundMe(fundMe.target, [lockTime]);
    } else {
        console.log("verification skipped..")
    }

    // init accounts
    const signers = await ethers.getSigners();
    const firstAccount = signers[0];
    console.log(`First account: ${firstAccount.address}`)
    console.log(`Available signers: ${signers.length}`)

    // fund contract with first account
    const fundTx = await fundMe.connect(firstAccount).fund({value: ethers.parseEther("0.5")})
    await fundTx.wait()

    // check balance of contract
    const balanceOfContract = await ethers.provider.getBalance(fundMe.target)
    console.log(`Balance of contract after first funding: ${ethers.formatEther(balanceOfContract)} ETH`)

    // check if second account exists
    if (signers.length > 1) {
        const secondAccount = signers[1];
        console.log(`Second account: ${secondAccount.address}`)
        
        // fund contract with second account
        const fundTx2 = await fundMe.connect(secondAccount).fund({value: ethers.parseEther("0.5")})
        await fundTx2.wait()
        
        // check balance of contract
        const balanceOfContract2 = await ethers.provider.getBalance(fundMe.target)
        console.log(`Balance of contract after second funding: ${ethers.formatEther(balanceOfContract2)} ETH`)
        
        // check mapping fundersToAmount
        const fundersToAmount1 = await fundMe.fundersToAmount(firstAccount.address)
        const fundersToAmount2 = await fundMe.fundersToAmount(secondAccount.address)
        console.log(`First account funded: ${ethers.formatEther(fundersToAmount1)} ETH`)
        console.log(`Second account funded: ${ethers.formatEther(fundersToAmount2)} ETH`)
    } else {
        console.log("Only one account available, skipping second account funding")
        
        // check mapping fundersToAmount for first account only
        const fundersToAmount1 = await fundMe.fundersToAmount(firstAccount.address)
        console.log(`First account funded: ${ethers.formatEther(fundersToAmount1)} ETH`)
    }


}

async function verifyFundMe(fundMeAddr, args) {
    await hre.run("verify:verify", {
        address: fundMeAddr,
        constructorArguments: args,
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });