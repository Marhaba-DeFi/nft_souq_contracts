// hardhat.config.js
require('@nomiclabs/hardhat-ethers');

async function main() {
	const ERC721RFactory = await ethers.getContractFactory("ERC721RFactory")
  
	// Start deployment, returning a promise that resolves to a contract object
	const erc721RFactory = await ERC721RFactory.deploy("Artwork Contract", "ART", 10, 1000, 86400, 10)
	await erc721RFactory.deployed()
	console.log("Contract deployed to address:", erc721RFactory.address)
  }
  
  main()
	.then(() => process.exit(0))
	.catch((error) => {
	  console.error(error)
	  process.exit(1)
	})
  