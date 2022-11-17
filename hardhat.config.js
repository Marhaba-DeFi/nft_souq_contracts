//  hardhat.config.js
require("@nomiclabs/hardhat-ethers");
require("hardhat-diamond-abi");
require('@typechain/hardhat')
require('@nomiclabs/hardhat-ethers')
// require('@nomiclabs/hardhat-waffle')
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");

require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
	solidity: "0.8.9",
	diamondAbi: {
		name: "souqNFTDiamond",
		strict: false
	},
	networks: {
		goerli: {
			url: `https://goerli.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
			accounts: [`0x${process.env.PRIVATE_KEY}`],
			gasPrice: 50000000000 
		},
		sepolia: {
			url: `https://sepolia.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
			accounts: [`0x${process.env.PRIVATE_KEY}`],
			gasPrice: 50000000000 
		}
	},
	etherscan: {
		apiKey: {
			goerli: process.env.ETH_SCAN
		}
	  }
};



