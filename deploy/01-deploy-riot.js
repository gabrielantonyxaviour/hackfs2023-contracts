const { verify } = require("../utils/verify")

const { ethers } = require("hardhat")
const fs = require("fs")

const developmentChains = ["localhost", "hardhat"]

const deployRiot = async function (hre) {
    // @ts-ignore
    const { getNamedAccounts, deployments, network } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    log("----------------------------------------------------")
    log("Deploying TheRiotProtocol and waiting for confirmations...")
    const riot = await deploy("TheRiotProtocol", {
        from: deployer,
        args: [0],
        log: true,
        maxFeePerGas: 38000000000,
        maxPriorityFeePerGas: 1000000000,
    })
    log(`TheRiotProtocol at ${riot.address}`)
}

module.exports = deployRiot
deployRiot.tags = ["all", "protocol", "riot"]
