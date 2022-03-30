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

  // initialize erc721Factory & erc1155Factory contracts
  const erc721FactoryFacet = await hre.ethers.getContractAt(
    'ERC721FactoryFacet',
    souqNFTDiamond.address,
  );
  await erc721FactoryFacet.erc721Init(erc721Name, erc721Symbol);
  console.log('erc721FactoryFacet initialized');

  const erc1155FactoryFacet = await hre.ethers.getContractAt(
    'ERC1155FactoryFacet',
    souqNFTDiamond.address,
  );
  const erc1155Name = 'NFT SOUQ';
  const erc1155Symbol = 'NFTSOUQ';
  await erc1155FactoryFacet.erc1155Init(erc1155Name, erc1155Symbol);
  console.log('erc1155FactoryFacet initialized');

  const marketFacet = await hre.ethers.getContractAt(
    'MarketFacet',
    souqNFTDiamond.address,
  );
  await marketFacet.marketInit();
  console.log('marketFacet initialized');

  const mediaFacet = await hre.ethers.getContractAt(
    'MediaFacet',
    souqNFTDiamond.address,
  );
  mediaFacet.mediaInit(souqNFTDiamond.address);
  console.log('mediaFacet initialized');

  updateContractAddresses(
    {
      DIAMOND: souqNFTDiamond.address,
      ERC721: facetsAdresses[0],
      ERC1155: facetsAdresses[1],
      MARKET: facetsAdresses[2],
      MEDIA: facetsAdresses[3],
    },
    network,
  );

  await marketFacet.configureMedia(mediaFacet.address);
  console.log('Configure Media address In market');

  await mediaFacet.setAdminAddress(signer.address);
  console.log('configured admin address');

  await mediaFacet.setCommissionPercentage(adminCommissionPercentage);
  console.log('configured Commission Percentage address');

  await mediaFacet.addCurrency(mrhbAddress);
  console.log('Currency 1 added');
  await mediaFacet.addCurrency(wbnbAddress);
  console.log('Currency 2 added');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
