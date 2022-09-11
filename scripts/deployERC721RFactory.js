// hardhat.config.js
require('@nomiclabs/hardhat-ethers');

async function main() {
	let name='Artwork Contract';
	let symbol='ART';
    let mintSupply = 1000;
    let mintingPrice = "1";
    let refundTime = 24 * 60 * 60 * 45;
    let maxMintPerUser = 5;
	const ERC721RFactory = await ethers.getContractFactory("ERC721RFactory")
  
	// Start deployment, returning a promise that resolves to a contract object
	const erc721RFactory = await ERC721RFactory.deploy(
		name,
		symbol,
		mintSupply,
		ethers.utils.parseEther(mintingPrice),
		refundTime,
		maxMintPerUser)
	await erc721RFactory.deployed()
	console.log("Contract deployed to address:", erc721RFactory.address)
  }
  
  main()
	.then(() => process.exit(0))
	.catch((error) => {
	  console.error(error)
	  process.exit(1)
	})
  