const { task } = require("hardhat/config")
task("register-organisation", "Registers an organisation")
    .addParam("name", "Name of Organisation")
    .addParam("symbol", "Symbol of Organisation")
    .addParam("client", "Client address")
    .setAction(async (taskArgs, hre) => {
        const { getNamedAccounts } = hre
        const { deployer } = await getNamedAccounts()
        if (network.name === "hardhat") {
            throw Error(
                'This command cannot be used on a local hardhat chain.  Specify a valid network or simulate an BurnToEarn request locally with "npx hardhat functions-simulate".'
            )
        }
        const { name, symbol, client } = taskArgs

        console.log(`Currently on Network ${network.name}`)

        const protocolFactory = await ethers.getContractFactory("TheRiotProtocol")
        const protocolContract = await protocolFactory.attach(
            "0x2f5b7835b0346201821d285295c0502a64ed391f"
        )
        const registerTx = await protocolContract.registerOrganisation(name, symbol, client, {
            from: deployer,
            value: ethers.parseEther("0.00000000000001"),
            gasLimit: 100000000,
            maxFeePerGas: 78000000000,
            maxPriorityFeePerGas: 2000000000,
        })

        // const getRegistrationFee = await protocolContract.getCreateFee()

        // console.log(getRegistrationFee.toString())

        const registerReceipt = await registerTx.wait()
        console.log(`Register Receipt`)
        console.log(registerReceipt)
    })
