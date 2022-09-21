// hardhat.config.js
require('@nomiclabs/hardhat-ethers');

async function main() {
	let name='Artwork Contract';
    let symbol='ART';

	const ERC721AFactory = await ethers.getContractFactory("ERC721AFactory")
  
	// Start deployment, returning a promise that resolves to a contract object
	const erc721AFactory = await ERC721AFactory.deploy(name, symbol)
	await erc721AFactory.deployed()
	console.log("Contract deployed to address:", erc721AFactory.address)
  }
  
  main()
	.then(() => process.exit(0))
	.catch((error) => {
	  console.error(error)
	  process.exit(1)
	})
  