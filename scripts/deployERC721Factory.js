// hardhat.config.js
require('@nomiclabs/hardhat-ethers');

async function main() {
	let name='Artwork Contract';
    let symbol='ART';
    let defaultRoyalty = true;
    let royaltyReceiver = ["0xaB856c0f5901432DEb88940C9423c555814BC0fd"];
    let royaltyFeesInBips = [1000];

	const ERC721Factory = await ethers.getContractFactory("ERC721Factory")
  
	// Start deployment, returning a promise that resolves to a contract object
	const erc721Factory = await ERC721Factory.deploy(
		name,
		symbol,
		defaultRoyalty,
		royaltyReceiver, 
		royaltyFeesInBips)
	await erc721Factory.deployed()
	console.log("Contract deployed to address:", erc721Factory.address)
  }
  
  main()
	.then(() => process.exit(0))
	.catch((error) => {
	  console.error(error)
	  process.exit(1)
	})
  