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
    'Diamond',
  );
  const souqNFTDiamond = await souqNFTDiamondFactory.deploy(signer.address);
  await souqNFTDiamond.deployed();
  console.log('souqNFTDiamond deployed to: ', souqNFTDiamond.address);

  // add facets to the souq NFT diamond
  const facetNames = [
    // 'ERC721FactoryFacet',
    'ERC1155FactoryFacet',
    // 'MarketFacet',
    // 'MediaFacet',
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

  const erc1155FactoryFacet = await hre.ethers.getContractAt(
    'ERC1155FactoryFacet',
    souqNFTDiamond.address,
  );
  const erc1155Name = 'NFT SOUQ';
  const erc1155Symbol = 'NFTSOUQ';
  await erc1155FactoryFacet.erc1155Init(erc1155Name, erc1155Symbol);
  console.log('erc1155FactoryFacet initialized');


  updateContractAddresses(
    {
      souqNFTDiamond: souqNFTDiamond.address,
    //   erc721FactoryFacet: facetsAdresses[0],
      erc1155FactoryFacet: facetsAdresses[0],
    //   marketFacet: facetsAdresses[2],
    //   mediaFacet: facetsAdresses[3],
    },
    network,
  );

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });