//  hardhat.config.js
require("@nomiclabs/hardhat-ethers");
require("hardhat-diamond-abi");
require('@typechain/hardhat')
require('@nomiclabs/hardhat-ethers')
require('@nomiclabs/hardhat-waffle')
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
	solidity: "0.8.9",
	diamondAbi: {
		name: "souqNFTDiamond",
		strict: false
	}
};
