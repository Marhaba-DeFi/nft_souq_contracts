// hardhat.config.js
require('@nomiclabs/hardhat-ethers');

async function main() {
	let name='Artwork Contract';
    let symbol='ART';
    let copies = 10;
    let defaultRoyalty = true;
    let royaltyReceiver = ["0xaB856c0f5901432DEb88940C9423c555814BC0fd"];
    let royaltyFeesInBips = [1000];
	const ERC1155Factory = await ethers.getContractFactory("ERC1155Factory")
  
	// Start deployment, returning a promise that resolves to a contract object
	const erc1155Factory = await ERC1155Factory.deploy(
		name,
		symbol,
		defaultRoyalty,
		royaltyReceiver, 
		royaltyFeesInBips
	)
	await erc1155Factory.deployed()
	console.log("Contract deployed to address:", erc1155Factory.address)
  }
  
  main()
	.then(() => process.exit(0))
	.catch((error) => {
	  console.error(error)
	  process.exit(1)
	})
  