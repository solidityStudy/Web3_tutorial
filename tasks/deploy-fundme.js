const { task } = require("hardhat/config");

task("deploy-fundme", "Deploy FundMe contract").setAction(async(taskArgs, hre)=>{
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
})

async function verifyFundMe(fundMeAddr, args) {
    await hre.run("verify:verify", {
        address: fundMeAddr,
        constructorArguments: args,
    });
}

module.exports = {}