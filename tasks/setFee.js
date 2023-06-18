const { task } = require("hardhat/config")
task("set-fee", "Sets the create organisation Fee").setAction(async (taskArgs, hre) => {
    const { getNamedAccounts } = hre
    const { deployer } = await getNamedAccounts()
    if (network.name === "hardhat") {
        throw Error(
            'This command cannot be used on a local hardhat chain.  Specify a valid network or simulate an BurnToEarn request locally with "npx hardhat functions-simulate".'
        )
    }

    console.log(`Currently on Network ${network.name}`)
    const protocolFactory = await ethers.getContractFactory("TheRiotProtocol")
    const protocolContract = await protocolFactory.attach(
        "0xBE38c5eefE99a622cA5F36b6306E5C61470B3974"
    )
    const setCreateFeeTx = await protocolContract.setCreateFee(2, {
        from: deployer,
        gasLimit: 30000000,
        maxFeePerGas: 48000000000,
        maxPriorityFeePerGas: 1600000000,
    })

    const setCreateFeeReceipt = await setCreateFeeTx.wait()
    console.log(`CreateFee Receipt`)
    console.log(setCreateFeeReceipt)
})
