// hardhat.config.js
const hre = require("hardhat");

async function main() {
	let name='Soul Art Bound';
    let symbol='SAB';
	let baseURI = "https://api.marhaba.staging/sbt/";

	console.log('Deploying SBTFactory: ',name,symbol)
	const SBTFactory = await hre.ethers.getContractFactory("SBTFactory")
	console.log('SBTFactory : ')

	// Start deployment, returning a promise that resolves to a contract object
	const SBTFactoryC = await SBTFactory.deploy(
		name,
		symbol
	)
	
	console.log('SBTFactoryC : ',SBTFactoryC.hash)
	await SBTFactoryC.deployed()
	console.log('SBTFactoryC : ',SBTFactoryC.address)

	console.log("Contract SBTFactory.sol deployed to address:", SBTFactoryC.address)
  }
  
  main()
	.then(() => process.exit(0))
	.catch((error) => {
	  console.error(error)
	  process.exit(1)
	})
  