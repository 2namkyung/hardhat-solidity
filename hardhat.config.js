require("@nomiclabs/hardhat-waffle");
require("dotenv").config();
const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  defaultNetwork: "rinkeby",
  solidity: "0.8.6",
  // solidity: "0.5.6",
  networks: {
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/aa667dc2bc3246ec87b1a333def3be21`,
      accounts: [PRIVATE_KEY],
    },

    matic: {
      url: "https://rpc-mumbai.matic.today",
      accounts: [PRIVATE_KEY],
    },
  },

  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 40000,
  },
};
