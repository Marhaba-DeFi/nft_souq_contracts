// utils
const hre = require('hardhat');
const { updateContractAddresses } = require('../utils/contractsManagement');
const { FacetCutAction, getSelectors } = require('../utils/diamond');

// const provider = new ethers.getDefaultProvider(process.env.NETWORK);
const network = hre.hardhatArguments.network;
async function main() {
  const adminAddress = '0x4281d6888D7a3A6736B0F596823810ffBd7D4808';
  const mrhbAddress = '0x45202955b5a2770A4dc526B6FB3634dDB275c8Df';
  const wbnbAddress = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd';
  const wethAddress = "0xc778417E063141139Fce010982780140Aa0cD5Ab";
  const adminCommissionPercentage = '1';

  const signers = await hre.ethers.getSigners();
  const signer = signers[0];
  console.log("signer is", signer.address)

  // deploying the souq NFT diamond
    const souqNFTDiamondFactory = await hre.ethers.getContractFactory(
      'Diamond',
    );
    const souqNFTDiamond = await souqNFTDiamondFactory.deploy(signer.address);
    await souqNFTDiamond.deployed();
    const address = souqNFTDiamond.address
    console.log('souqNFTDiamond deployed to: ', souqNFTDiamond.address);

  // add facets to the souq NFT diamond
  const facetNames = [
    'MediaFacet',
    'ERC1155FactoryFacet',
    'ERC721FactoryFacet',
    'MarketFacet'
  ];

  const facetsAdresses = [];
  const cut = [];

  for (const facetName of facetNames) {
    const Facet = await hre.ethers.getContractFactory(facetName);
    const facet = await Facet.deploy();
    await facet.deployed();
    facetsAdresses.push(facet.address);
    console.log(`${facetName} deployed: ${facet.address}`);
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet),
    });
  }

  const diamondCutFacet = await hre.ethers.getContractAt(
    'DiamondCutFacet',
    souqNFTDiamond.address,
  );
  await diamondCutFacet.diamondCut(cut, hre.ethers.constants.AddressZero, '0x');

  //Media deployment

  const mediaFacet = await hre.ethers.getContractAt(
    'MediaFacet',
    souqNFTDiamond.address,
  );
  await mediaFacet.mediaFacetInit(souqNFTDiamond.address);
  console.log('Media is initialized');

//token deployment
  const erc1155FactoryFacet = await hre.ethers.getContractAt(
    'ERC1155FactoryFacet',
    souqNFTDiamond.address,
  );
  const erc1155Name = 'NFT1155 SOUQ';
  const erc1155Symbol = 'NFT1155SOUQ';
  await erc1155FactoryFacet.erc1155FactoryFacetInit(erc1155Name, erc1155Symbol);
  console.log('erc1155FactoryFacet initialized');

  const erc721FactoryFacet = await hre.ethers.getContractAt(
    'ERC721FactoryFacet',
    souqNFTDiamond.address,
  );
  const erc721Name = 'NFT721 SOUQ';
  const erc721Symbol = 'NFT721SOUQ';
  await erc721FactoryFacet.erc721FactoryFacetInit(erc721Name, erc721Symbol);
  console.log('erc721FactoryFacet initialized');

  //Market deployment

  const marketFacet = await hre.ethers.getContractAt(
    'MarketFacet',
    souqNFTDiamond.address,
  );

  const marketName = 'Marketplace';
  const marketVersion = '1.0.0';
  await marketFacet.marketFacetInit(marketName, marketVersion);
  console.log('MARKET is initialized');

  const marketAddress = await marketFacet.getAddress();
  console.log('Media IS initialized with address', marketAddress );

  //Minting token from 1155 contract
  const token721 = await mediaFacet.mintTokenMedia(
    signer.address,
    0,
    "ERC721",
    address,
    1,
    "12345",
    [signer.address],
    [100]
  );

  console.log("Owner of token721", await erc721FactoryFacet.ownerOf(0))

  // const mediaFacet = await hre.ethers.getContractAt(
  //   'MediaFacet',
  //   souqNFTDiamond.address,
  // );
  // await mediaFacet.mediaInit(souqNFTDiamond.address);
  // console.log('Media IS initialized');

  // const mediaAddress = await mediaFacet.acceptBidMedia();
  // console.log('Media IS initialized with address', mediaAddress );

//
// nft address = 0xCa64b2CF6aAF5eDE8E97f570aef13B14751f01Db
// nft seller = 0xf749e7913dE91509332fB8D46D0Ae778aE6b7397
// owner signiture = 0xde1d06976666fe06d2f77b9cebbc17f9d71f47186ae986d3db9e9458e564bef61dfb907d6287dd80b7a6e2c38a54cff7235a802603ea420982b8b5bb67419cd11c

// bider = 0xd51b3474613847E7C19FfEE67A26f17D1b3770D2
// bider signiture = 0x52636a5b225500135456c4782d520e2998adc828581feedd8fc3785e0ade492826705620af1161c46fd50bb601fb4b0db0d5ad2ad0b52ea4e5c7460460b691481b
//currencyAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab

// Test transfer:

// const marketFacet = await hre.ethers.getContractAt(
//   'MarketFacet',
//   "0x72acf74c7298D89eFaEbd23118f8b7c343d530e9",
// );

// await marketFacet.setApprovedCrypto("0xc778417E063141139Fce010982780140Aa0cD5Ab", true);

// const result = await marketFacet.acceptBid(
//   "ERC721",
//   "0xCa64b2CF6aAF5eDE8E97f570aef13B14751f01Db",
//   "0xc778417E063141139Fce010982780140Aa0cD5Ab",
//   "0xf749e7913dE91509332fB8D46D0Ae778aE6b7397",
//   "0xd51b3474613847E7C19FfEE67A26f17D1b3770D2",
//   "1",
//   "1000000000000000",
//   "1",
//   "0x52636a5b225500135456c4782d520e2998adc828581feedd8fc3785e0ade492826705620af1161c46fd50bb601fb4b0db0d5ad2ad0b52ea4e5c7460460b691481b",
//   "0xde1d06976666fe06d2f77b9cebbc17f9d71f47186ae986d3db9e9458e564bef61dfb907d6287dd80b7a6e2c38a54cff7235a802603ea420982b8b5bb67419cd11c"
// );
// console.log("the result is ", result)

  // updateContractAddresses(
  //   {
  //     souqNFTDiamond: souqNFTDiamond.address,
  //   //   erc721FactoryFacet: facetsAdresses[0],
  //     erc1155FactoryFacet: facetsAdresses[0],
  //   //   marketFacet: facetsAdresses[2],
  //   //   mediaFacet: facetsAdresses[3],
  //   },
  //   network,
  // );

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });