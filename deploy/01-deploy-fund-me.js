const { getNamedAccounts, deployments } = require("hardhat")

module.exports = async({getNamedAccounts, deployments}) => {
    const firstAccount = (await getNamedAccounts()).firstAccount
    const {deploy} = deployments

    await deploy("FundMe",{
        from: firstAccount,
        args: [180],
        log: true
    })
}

module.exports.tags = ["all", "fundme"] 