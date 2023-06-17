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
        args: [31],
        log: true,
        maxFeePerGas: 38000000000,
        maxPriorityFeePerGas: 1000000000,
    })
    log(`TheRiotProtocol at ${riot.address}`)
    // if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    //     await verify(riot.address, [])
    // }

    fs.readFile("utils/deployments.json", "utf8", (err, data) => {
        if (err) {
            console.error("Error reading JSON file:", err)
            return
        }

        let jsonData
        try {
            jsonData = JSON.parse(data)
        } catch (error) {
            console.error("Error parsing JSON:", error)
            return
        }

        jsonData[network.chainId] = { ...jsonData[network.chainId], riot: riot.address }

        fs.writeFile(filePath, JSON.stringify(jsonData, null, 2), (err) => {
            if (err) {
                console.error("Error writing JSON file:", err)
            } else {
                console.log("JSON file updated successfully.")
            }
        })
    })
}

module.exports = deployRiot
deployRiot.tags = ["all", "protocol", "riot"]
