require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-etherscan');
require('./tasks/mint.config');
require('dotenv').config();
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});
const { removeConsoleLog } = require('hardhat-preprocessor');

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  networks: {
    hardhat: {
      forking: {
        enabled: process.env.FORKING === 'true',
        url: 'https://eth-kovan.alchemyapi.io/v2/7hXx5tOjA95V0sjNScp2g6Uf-RXq5cU6',
      },
      live: false,
      saveDeployments: true,
      tags: ['test', 'local'],
    },
    bscTestnet: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545',
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [process.env.PRIVATE_KEY],
    },
    kovan: {
      url: 'https://kovan.infura.io/v3/efa4b4ab6b5e41f6ac9818107e359ac6',
      accounts: [process.env.PRIVATE_KEY],
    },
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/efa4b4ab6b5e41f6ac9818107e359ac6',
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 100000000000,
    },
    mainnet: {
      url: 'https://mainnet.infura.io/v3/efa4b4ab6b5e41f6ac9818107e359ac6',
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 24000000000,
    },
    ganache: {
      url: 'http://localhost:8545',
      accounts: {
        mnemonic:
          'cupboard tennis easy year sunset puppy silent soul athlete good flight resemble',
        path: 'm/44\'/60\'/0\'/0',
        initialIndex: 0,
        count: 20,
      },
    },
    polygonMainnet: {
      url: "https://polygon-mainnet.g.alchemy.com/v2/ARoEjFsFTU6nG5NG6bkBth7QabDERGoD",
      chainId: 137,
      accounts: [process.env.PRIVATE_KEY],
      gasPrice: 70000000000
    },
  },

  mocha: {
    // enableTimeouts: false,
    timeout: 20000,
  },
  // solidity: "0.7.3",
  preprocess: {
    eachLine: removeConsoleLog(
      (bre) =>
        bre.network.name !== 'hardhat' && bre.network.name !== 'localhost',
    ),
  },
  solidity: {
    compilers: [
      {
        version: '0.8.0',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  typechain: {
    outDir: 'types',
    target: 'ethers-v5',
  },
  watcher: {
    compile: {
      tasks: ['compile'],
      files: ['./contracts'],
      verbose: true,
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
