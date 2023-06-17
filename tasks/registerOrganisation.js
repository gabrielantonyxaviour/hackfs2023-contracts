const { ethers } = require("hardhat")
const { task } = require("hardhat/config")

task("registerOrganisation", "Registers an organisation")
    .addParam("name", "Name of Organisation")
    .addParam("symbol", "Symbol of Organisation")
    .addParam("client", "Client address")
    .setAction(async (taskArgs, hre) => {
        if (network.name === "hardhat") {
            throw Error(
                'This command cannot be used on a local hardhat chain.  Specify a valid network or simulate an BurnToEarn request locally with "npx hardhat functions-simulate".'
            )
        }

        console.log(`Currently on Network ${network.name}`)

        const protocolFactory = await ethers.getContractFactory("TheRiotProtocol")
        const protocolContract = await protocolFactory.attach(
            "0x7f9E008F8d7de1CE3Cd32508a8a8B7304a9CD45F"
        )
        const isOrganisation = await protocolContract.isOrganisation(taskArgs.client)
        console.log(`Is ${taskArgs.client} an organisation? ${isOrganisation}`)
    })

