// Diamond deployment test - Ep1
// In this deployment file we will try deploying diamond and all of the facets
//Also we would initiate all the facets the address of diamond would be used in the following deployments
// deployMintingDiamond.js and deployAcceptBid.js
const hre = require("hardhat");
const { FacetCutAction, getSelectors } = require("../utils/diamond");

const souqNFTDiamondAtrificat = require("../artifacts/hardhat-diamond-abi/HardhatDiamondABI.sol/souqNFTDiamond.json")

async function main({ withFacets } = { withFacets: true }) {

	const signers = await hre.ethers.getSigners();
	// the owner 
	const signer = signers[0];
	// other participants
	// const alice = signers[1];
	// const bob = signers[2];
	// const carol = signers[3];
	// const dave = signers[4];
	// const frank = signers[5];


	// deploying the souq NFT diamond
	const souqNFTDiamondFactory = await hre.ethers.getContractFactory(
		"Diamond",
	);
	let souqNFTDiamond = await souqNFTDiamondFactory.deploy(signer.address);
	await souqNFTDiamond.deployed();

	// Printing out the diamond's address
	console.log("Diamond address is: ", souqNFTDiamond.address)
	//

	let ownershipFacet = await hre.ethers.getContractAt(
		"OwnershipFacet",
		souqNFTDiamond.address
	);

	let diamondCutFacet = await hre.ethers.getContractAt(
		"DiamondCutFacet",
		souqNFTDiamond.address
	);

	let diamondLoupeFacet = await hre.ethers.getContractAt(
		"DiamondLoupeFacet",
		souqNFTDiamond.address
	);

	let mediaFacet;
	let erc1155FactoryFacet;
	let erc721FactoryFacet;
	let marketFacet;

	if (withFacets) {
		// add facets to the souq NFT diamond

		const facetNames = [
			"MediaFacet",
			"ERC1155FactoryFacet",
			"ERC721FactoryFacet",
			"MarketFacet",
		];

		const facetsAdresses = [];
		const cut = [];

		for (const facetName of facetNames) {
			const Facet = await hre.ethers.getContractFactory(facetName);
			const facet = await Facet.deploy();
			await facet.deployed();
			facetsAdresses.push(facet.address);
			
			cut.push({
				facetAddress: facet.address,
				action: FacetCutAction.Add,
				functionSelectors: getSelectors(facet),
			});
		}

		// add facets functions to the diamond
		await diamondCutFacet.diamondCut(cut, hre.ethers.constants.AddressZero, '0x');

		// media facet
		mediaFacet = await hre.ethers.getContractAt(
			"MediaFacet",
			souqNFTDiamond.address
		);
		const txMediaInit = await mediaFacet.mediaFacetInit(souqNFTDiamond.address,{ gasLimit: 10_600_000 });
		console.log("mediaFacet is initiated ")
		txMediaInit.wait();
		
		// erc1155 facet
		erc1155FactoryFacet = await hre.ethers.getContractAt(
			"ERC1155FactoryFacet",
			souqNFTDiamond.address
		);
		const erc1155Name = "NFT1155 SOUQ";
		const erc1155Symbol = "NFT1155SOUQ";
		const tx1155Init = await erc1155FactoryFacet.erc1155FactoryFacetInit(
			erc1155Name,
			erc1155Symbol,
			{ gasLimit: 10_600_000 }
		);
		console.log("erc1155FactoryFacet is initiated ")
		tx1155Init.wait();
		
		// erc721 facet
		erc721FactoryFacet = await hre.ethers.getContractAt(
			"ERC721FactoryFacet",
			souqNFTDiamond.address
		);
		const erc721Name = "NFT721 SOUQ";
		const erc721Symbol = "NFT721SOUQ";
		const tx721Init =  await erc721FactoryFacet.erc721FactoryFacetInit(erc721Name, erc721Symbol,{ gasLimit: 10_600_000 });
		console.log("erc721FactoryFacet is initiated ")
		tx721Init.wait();

		// market facet
		marketFacet = await hre.ethers.getContractAt(
			"MarketFacet",
			souqNFTDiamond.address
		);

		const marketName = "SouqMarketPlace";
		const marketVersion = "1.0.0";
		const txMarketInit = await marketFacet.marketFacetInit(marketName, marketVersion, { gasLimit: 10_600_000 });
		console.log("Marketplace is initiated ")
		txMarketInit.wait();
	}

	return {
		souqNFTDiamond,
		ownershipFacet,
		diamondLoupeFacet,
		diamondCutFacet,
		erc721FactoryFacet,
		erc1155FactoryFacet,
		marketFacet,
		mediaFacet,
		signer,
		alice,
		bob,
		carol,
		dave,
		frank,
	};
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
	main()
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error);
			process.exit(1);
		});
}

exports.deployDiamond = main;
