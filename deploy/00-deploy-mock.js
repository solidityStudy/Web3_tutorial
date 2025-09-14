const { getNamedAccounts, deployments } = require("hardhat")
const { DECIMAL, INITIAL_ANSWER } = require("../helper-hardhat-config")

module.exports = async({getNamedAccounts, deployments}) => {
    const firstAccount = (await getNamedAccounts()).firstAccount
    const {deploy} = deployments

    await deploy("MockV3Aggregator",{
        from: firstAccount,
        args: [DECIMAL, INITIAL_ANSWER],
        log: true
    })
}

module.exports.tags = ["all", "mock"] 