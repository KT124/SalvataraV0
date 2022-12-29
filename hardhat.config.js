require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-waffle");
require("hardhat-contract-sizer");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-etherscan");
require("solidity-coverage");
require("dotenv").config();


/** @type import('hardhat/config').HardhatUserConfig */

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  // configureYulOptimizer: true,
  // solcOptimizerDetails:,


  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 99999,
        // details: {
        //   yul: true,
        //   yulDetails: {
        //     stackAllocation: true,
        //     optimizerSteps: "dhfoDgvulfnTUtnIf",
        //   }
        // }

      },
    },
  },
  networks: {
    // hardhat: {
    //   forking: {
    //     url: `https://mainnet.infura.io/v3/${process.env.RPC}`,
    //     // blockNumber: 15618886,
    //   },
    // },
    // ganache: {
    //   url: "http://127.0.0.1:8545",
    //   // accounts: {
    //   //   mnemonic:
    //   //     "toss run misery mango slice method current april health kidney idea remove",
    //   // },

    //   chainId: 1337,
    // },

    // goerli: {
    //   url: `https://goerli.infura.io/v3/${process.env.RPC}`,
    //   accounts: [process.env.KEY],
    //   chainId: 5,
    // },

    // matic: {
    //   url: "https://rpc-mumbai.maticvigil.com",
    //   accounts: [process.env.KEY],
    // },
  },

  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
    only: [],
  },

  gasReporter: {
    currency: "gwei",
    gasPrice: 50,
    // enabled: process.env.REPORT_GAS ? true : false,
  },

  etherscan: {
    apiKey: process.env.SCAN,
  },
};
