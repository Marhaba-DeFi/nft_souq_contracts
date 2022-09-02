// hardhat.config.js
require('@nomiclabs/hardhat-ethers');

async function main() {
	const ERC721Factory = await ethers.getContractFactory("ERC721Factory")
  
	// Start deployment, returning a promise that resolves to a contract object
	const erc721Factory = await ERC721Factory.deploy("Artwork Contract", "ART", false, ["0xaB856c0f5901432DEb88940C9423c555814BC0fd"], [1000])
	await erc721Factory.deployed()
	console.log("Contract deployed to address:", erc721Factory.address)
  }
  
  main()
	.then(() => process.exit(0))
	.catch((error) => {
	  console.error(error)
	  process.exit(1)
	})
  