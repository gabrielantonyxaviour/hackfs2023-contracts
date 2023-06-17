const { verify } = require("../utils/verify")

const { ethers } = require("hardhat")

const developmentChains = ["localhost", "hardhat"]

const deployDealClient = async function (hre) {
    // @ts-ignore
    const { getNamedAccounts, deployments, network } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    log("----------------------------------------------------")
    log("Deploying DealClient and waiting for confirmations...")
    const client = await deploy("DealClient", {
        from: deployer,
        args: ["0x7f9E008F8d7de1CE3Cd32508a8a8B7304a9CD45F"],
        log: true,
        maxFeePerGas: 38000000000,
        maxPriorityFeePerGas: 1000000000,
    })
    log(`DealClient at ${client.address}`)
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

        jsonData[network.chainId] = { ...jsonData[network.chainId], client: client.address }

        fs.writeFile(filePath, JSON.stringify(jsonData, null, 2), (err) => {
            if (err) {
                console.error("Error writing JSON file:", err)
            } else {
                console.log("JSON file updated successfully.")
            }
        })
    })
}

module.exports = deployDealClient
deployDealClient.tags = ["all", "client", "riot"]
