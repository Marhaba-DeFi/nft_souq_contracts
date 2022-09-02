// Diamond deployment test - Ep3
// In this deployment test we would place a bid for tokenId 0 of erc721FactoryFacet usinf the second account
//Also accepting the bid by the owner
const hre = require("hardhat");

async function main() {
	
	//On which network you are
	const network = await ethers.provider.getNetwork();
	const chainId = network.chainId.toString();
	console.log("Network name=", network.name);
	console.log("Network chain id=", chainId);

    const signers = await hre.ethers.getSigners();
    // the owner 
    const owner = signers[0];
    const bidder = signers[1];

    //Address of the bidder and owner of whoile erc20 at first
    console.log("signer 0 is", owner.address)
    console.log("Bidder is", bidder.address)

	//Insert the diamond address you have created at EP1
    const diamondAddress = "";
    let erc20Address = ""

////////////// Getting contracts ready
    const mediaFacet = await hre.ethers.getContractAt(
        'MediaFacet',
        diamondAddress);
    console.log("Media facet is got")


	console.log("Token number 0 of 721 exists: ", await mediaFacet.istokenIdExistMedia(0,"ERC721"));
	console.log("Mock token is approved: ", await mediaFacet.getApprovedCryptoMedia(erc20Address));
	console.log("Platform commission fee: ", parseInt(await mediaFacet.getAdminCommissionPercentageMedia()));
	const collabTarget0 = await mediaFacet.getCollaboratorsMedia(diamondAddress, 0); 
	console.log("Collaborators of token0 are ",  collabTarget0 ) 
	console.log("Shares of token0 are ", (collabTarget0["collabFraction"]))

	const mockerc20 = await hre.ethers.getContractAt(
        'ERC20Mock',
        erc20Address);
    console.log("Mock erc20 facet is got")
	const txapprovingDiamondByBidder = await mockerc20.connect(bidder).approve(diamondAddress, BigInt(10**30), { gasLimit: 10_600_000 });
	txapprovingDiamondByBidder.wait();

// /////////////////

//internal token
let nftAddress = diamondAddress
let nftSeller = owner.address
let bid = BigInt(10**16).toString();

let ownerSigniture = await owner._signTypedData(
	{
		name: "SouqMarketPlace",
		version: "1.0.0",
		chainId: chainId,
		verifyingContract: diamondAddress
	},
	{Bid: [
		{name: "nftContAddress", type: "address"},
		{name: 'tokenID', type: 'uint256'},
		{name: 'copies', type: 'uint256'},
		{name: 'currencyAddress', type: 'address'},
		{name: 'bid', type: 'uint256'}
		],
	},
	{
		nftContAddress: diamondAddress,
		tokenID: "0",
		copies: "1",
		currencyAddress: erc20Address,
		bid: bid},
)
console.log("Owner Signiture is: ", ownerSigniture)

let bider = bidder.address
let currencyAddress = erc20Address
let biderSigniture = await bidder._signTypedData(
	{
		name: "Marketplace",
		version: "1.0.0",
		chainId: chainId,
		verifyingContract: diamondAddress
	},
	{Bid: [
		{name: "nftContAddress", type: "address"},
		{name: 'tokenID', type: 'uint256'},
		{name: 'copies', type: 'uint256'},
		{name: 'currencyAddress', type: 'address'},
		{name: 'bid', type: 'uint256'}
		],
	},
	{
		nftContAddress: diamondAddress,
		tokenID: "0",
		copies: "1",
		currencyAddress: erc20Address,
		bid: bid},
)
console.log("Bidder Signiture is: ", biderSigniture)


//Test transfer:

//const approvingMedia = await mediaFacet.approveMarketForAllMedia();

const result = await mediaFacet.connect(owner).acceptBidMedia(
  "ERC721",
  nftAddress,
  currencyAddress,
  nftSeller,
  bider,
  "0",
  bid,
  "1",
  biderSigniture,
  ownerSigniture,
  { gasLimit: 10_600_000 }
);
console.log("the result is ", result)


}

if (require.main === module) {
	main()
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error);
			process.exit(1);
		});
}

exports.deployDiamond = main;