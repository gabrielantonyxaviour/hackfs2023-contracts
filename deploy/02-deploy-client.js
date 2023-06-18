const { verify } = require("../utils/verify")

const { ethers } = require("hardhat")

const fs = require("fs")
const deployDealClient = async function (hre) {
    const { getNamedAccounts, deployments, network } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    log("----------------------------------------------------")
    log("Deploying DealClient and waiting for confirmations...")
    const client = await deploy("DealClient", {
        from: deployer,
        args: ["0x9DbB3Bd263E9C782f5784a73418580b455D2e6df"],
        log: true,
        maxFeePerGas: 38000000000,
        maxPriorityFeePerGas: 1000000000,
    })
    log(`DealClient at ${client.address}`)
}

module.exports = deployDealClient
deployDealClient.tags = ["all", "client", "riot"]
