require("@nomicfoundation/hardhat-toolbox")
require("hardhat-contract-sizer")

//require("./tasks")
require("dotenv").config()

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

// const SCROLL_RPC_URL = process.env.SCROLL_RPC_URL
// const TAIKO_RPC_URL = process.env.TAIKO_RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x"
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY
// Your API key for Etherscan, obtain one at https://etherscan.io/
// const REPORT_GAS = process.env.REPORT_GAS || false

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
        },
        localhost: {
            chainId: 31337,
        },
        goerli: {
            url: "https://rpc.ankr.com/eth_goerli",
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            chainId: 5,
        },
        calibration: {
            chainId: 314159,
            url: "https://api.calibration.node.glif.io/rpc/v1",
            accounts: [PRIVATE_KEY],
            gasPrice: 20e9,
            gas: 25e6,
        },
        FilecoinMainnet: {
            chainId: 314,
            url: "https://api.node.glif.io",
            accounts: [PRIVATE_KEY],
        },
        polygonMumbai: {
            url: "https://rpc.ankr.com/polygon_mumbai",
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            chainId: 80001,
            gasPrice: 20e9,
            gas: 25e6,
        },
        scroll: {
            url: "https://scroll-testnet.blockpi.network/v1/rpc/public",
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            chainId: 534353,
        },
        taiko: {
            url: "https://rpc.a2.taiko.xyz",
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            chainId: 167004,
        },
        chiado: {
            url: "https://rpc.chiadochain.net",
            gasPrice: 1000000000,
            saveDeployments: true,
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            chainId: 10200,
        },
        gnosis: {
            url: "https://gnosis.blockpi.network/v1/rpc/public",
            gasPrice: 2000000000,
            saveDeployments: true,
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            chainId: 100,
        },
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
    },
    solidity: {
        compilers: [
            {
                version: "0.8.17",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000,
                        details: { yul: false },
                    },
                },
            },
        ],
    },
    allowUnlimitedContractSize: true,
    mocha: {
        timeout: 500000, // 500 seconds max for running tests
    },
    gasReporter: {
        enabled: true,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        coinmarketcap: process.env.COINMARKETCAP_API_KEY,
        token: "MATIC",
    },
}
