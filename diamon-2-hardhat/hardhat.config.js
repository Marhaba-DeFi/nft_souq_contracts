
// /* global ethers task */
// require('@nomiclabs/hardhat-waffle')

// // This is a sample Hardhat task. To learn how to create your own go to
// // https://hardhat.org/guides/create-task.html
// task('accounts', 'Prints the list of accounts', async () => {
//   const accounts = await ethers.getSigners()

//   for (const account of accounts) {
//     console.log(account.address)
//   }
// })

// // You need to export an object to set up your config
// // Go to https://hardhat.org/config/ to learn more

// /**
//  * @type import('hardhat/config').HardhatUserConfig
//  */
// module.exports = {
//   solidity: '0.8.6',
//   settings: {
//     optimizer: {
//       enabled: true,
//       runs: 200
//     }
//   }
// }
// /** @type import('hardhat/config').HardhatUserConfig */
require('@nomiclabs/hardhat-waffle');

const INFURA_URL = "https://eth-rinkeby.alchemyapi.io/v2/VHQ8cHpIDV1h944x5EYfDX16vO8eYc-6";
const alchemy_url = "https://eth-goerli.g.alchemy.com/v2/gTtgWv_cVcaJnZtsOhwp_dcXBUxRl3hI"
const PRIVATE_KEY = "0x6e6dfc1c884234152040ad146f8733b79cd95128ac7de5dbf90566d86bdb2c54";
module.exports = {
  solidity: "0.8.10",
  networks: {
    goerli: {
      url:alchemy_url,
      accounts: [PRIVATE_KEY]
    },
    rinkeby:{
      url:INFURA_URL,
      accounts: [PRIVATE_KEY],
      gas: 6000000,
    }
  }
};