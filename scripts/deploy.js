// utils
const hre = require('hardhat');
const { updateContractAddresses } = require('../utils/contractsManagement');
const { FacetCutAction, getSelectors } = require('../utils/diamond');

// const provider = new ethers.getDefaultProvider(process.env.NETWORK);
const network = hre.hardhatArguments.network;
async function main() {
  const erc721Name = 'NFT SOUQ';
  const erc721Symbol = 'NFTSOUQ';
  const adminAddress = '0x4281d6888D7a3A6736B0F596823810ffBd7D4808';
  const mrhbAddress = '0x45202955b5a2770A4dc526B6FB3634dDB275c8Df';
  const wbnbAddress = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd';
  const adminCommissionPercentage = '1';

  const signers = await hre.ethers.getSigners();
  const signer = signers[0];

  // deploying the souq NFT diamond
  const souqNFTDiamondFactory = await hre.ethers.getContractFactory(
    'SouqNFTDiamond',
  );
  const souqNFTDiamond = await souqNFTDiamondFactory.deploy(signer.address);
  await souqNFTDiamond.deployed();
  console.log('souqNFTDiamond deployed to: ', souqNFTDiamond.address);

  // add facets to the souq NFT diamond
  const facetNames = [
    'ERC721FactoryFacet',
    'ERC1155FactoryFacet',
    'MarketFacet',
    'MediaFacet',
  ];

  const cut = [];

  for (const facetName of facetNames) {
    const Facet = await hre.ethers.getContractFactory(facetName);
    const facet = await Facet.deploy();
    await facet.deployed();
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

  // initialize contracts
  const erc721FactoryFacet = await hre.ethers.getContractAt(
    'ERC721FactoryFacet',
    souqNFTDiamond.address,
  );
  await erc721FactoryFacet.erc721Init(erc721Name, erc721Symbol);
  const name = await erc721FactoryFacet.name();
  const symbol = await erc721FactoryFacet.symbol();
  console.log('name: ', name);
  console.log('symbol: ', symbol);

  // let erc721 = await hre.ethers.getContractFactory('ERC721Factory');
  // erc721 = await erc721.deploy(erc721Name, erc721Symbol);
  // await erc721.deployed();
  // console.log('erc721 Token deployed at:', erc721.address);

  // // const erc1155Uri = '';
  // const erc1155Name = 'NFT SOUQ';
  // const erc1155Symbol = 'NFTSOUQ';
  // let erc1155 = await hre.ethers.getContractFactory('ERC1155Factory');
  // // erc1155 = await erc1155.deploy(erc1155Uri)
  // erc1155 = await erc1155.deploy(erc1155Name, erc1155Symbol);
  // await erc1155.deployed();
  // console.log('erc1155 Token deployed at:', erc1155.address);
  // let market = await hre.ethers.getContractFactory('Market');
  // market = await market.deploy();
  // await market.deployed();
  // console.log('Market deployed at:', market.address);
  // let media = await hre.ethers.getContractFactory('Media');
  // media = await media.deploy(erc1155.address, erc721.address, market.address);
  // await media.deployed();
  // console.log('media deployed at:', media.address);

  // updateContractAddresses(
  //   {
  //     ERC721: erc721.address,
  //     ERC1155: erc1155.address,
  //     MARKET: market.address,
  //     MEDIA: media.address,
  //   },
  //   network,
  // );
  // await market.configureMedia(media.address);
  // console.log('Configure Media address In market');
  // await erc1155.configureMedia(media.address);
  // await erc721.configureMedia(media.address);
  // console.log('Media Added In ERC');
  // await media.setAdminAddress(adminAddress);
  // console.log('configured admin address');
  // await media.setCommissionPercentage(adminCommissionPercentage);
  // console.log('configured Commission Percentage address');
  // await media.addCurrency(mrhbAddress);
  // console.log('Currency 1 added');
  // await media.addCurrency(wbnbAddress);
  // console.log('Currency 2 added');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
