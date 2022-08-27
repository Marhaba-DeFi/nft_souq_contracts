// hardhat.config.js
require('@nomiclabs/hardhat-ethers');

async function main() {
	const ERC1155Factory = await ethers.getContractFactory("ERC1155Factory")
  
	// Start deployment, returning a promise that resolves to a contract object
	const erc1155Factory = await ERC1155Factory.deploy("Artwork Contract", "ART", false, ["0xaB856c0f5901432DEb88940C9423c555814BC0fd"], [1000])
	await erc1155Factory.deployed()
	console.log("Contract deployed to address:", erc1155Factory.address)
  }
  
  main()
	.then(() => process.exit(0))
	.catch((error) => {
	  console.error(error)
	  process.exit(1)
	})
  