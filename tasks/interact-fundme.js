const { task } = require("hardhat/config");

task("interact-fundme", "Interact with FundMe contract").addParam("addr","FundMe contract address").setAction(async(taskArgs, hre)=>{
    const fundMeFactory = await ethers.getContractFactory("FundMe");
    const fundMe = await fundMeFactory.attach(taskArgs.addr);
    // init accounts
    const signers = await ethers.getSigners();
    const firstAccount = signers[0];
    console.log(`First account: ${firstAccount.address}`)
    console.log(`Available signers: ${signers.length}`)
    
    // fund contract with first account
    const fundTx = await fundMe.connect(firstAccount).fund({value: ethers.parseEther("0.05")})
    await fundTx.wait()
    
    // check balance of contract
    const balanceOfContract = await ethers.provider.getBalance(fundMe.target)
    console.log(`Balance of contract after first funding: ${ethers.formatEther(balanceOfContract)} ETH`)
    
    // check if second account exists
    if (signers.length > 1) {
        const secondAccount = signers[1];
        console.log(`Second account: ${secondAccount.address}`)
        
        // fund contract with second account
        const fundTx2 = await fundMe.connect(secondAccount).fund({value: ethers.parseEther("0.05")})
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
})

module.exports = {}