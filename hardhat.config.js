require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      { version: "0.5.0" },
      { version: "0.5.5" },
      { version: "0.6.6" },
      { version: "0.8.9" } 
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-mainnet.g.alchemy.com/v2/YViRFlzFSftOMSgTV6oTNTOcDH3EnD2a",
        blockNumber: 15420752
      }
    },
    georli_testnet: {
      url: "https://eth-goerli.g.alchemy.com/v2/NV5Qt3lkyEw1oiCMm72kwKB7B6Bk46aD",
      chainId: 5,
      accounts: ["0x0ae9be380d18a5418bf4d34d44d575c58b2ffa371cf4394444f37bccdf3f2ff7"],
    },
    mainnet: {
      url: "https://eth-mainnet.g.alchemy.com/v2/YViRFlzFSftOMSgTV6oTNTOcDH3EnD2a",
      chainId: 1
    }
  },
  etherscan: {
    apiKey: {
      bscTestnet: "MS1P67SGGQPX2ISWVXK1P9VKV5EEV1TNA4"
    }
  }
};
