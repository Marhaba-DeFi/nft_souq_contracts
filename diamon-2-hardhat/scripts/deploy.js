
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

  //Address of the bidder and owner of whoile erc20 at first
  const signers = await hre.ethers.getSigners();
  const signer = signers[0];
  console.log("signer 0 is", signer.address)

  // Address of the minter and owner of nft token
  // const signer1 = signers[1];
  // console.log("signer 1 is", signer1.address)

  // // Royality address1 for nft
  // const signer2 = signers[2];
  // console.log("signer 2 is", signer2.address)

  // // Royality address2 for nft
  // const signer3 = signers[3];
  // console.log("signer 3 is", signer3.address)

  // // Contributer address1 for nft
  // const signer4 = signers[4];
  // console.log("signer 4 is", signer4.address)

  // // Contributer address2 for nft
  // const signer5 = signers[5];
  // console.log("signer 5 is", signer5.address)

//// Minting erc20 mock token

  // const ERC20Mock = await hre.ethers.getContractFactory(
  //   'ERC20Mock',
  // );
  // const erc20Mock = await ERC20Mock.deploy("MARHABA", "MRHB", 1_000_000);
  // await erc20Mock.deployed();
  // const erc20Address = erc20Mock.address
  // console.log('Mock erc20 is deployed to: ', erc20Address);
  // console.log('The balance of signer0 is: ',  parseInt(await erc20Mock.balanceOf(signer.address)))

///////////////////////////////////////


  // deploying the souq NFT diamond
    const souqNFTDiamondFactory = await hre.ethers.getContractFactory(
      'Diamond',
    );
    const souqNFTDiamond = await souqNFTDiamondFactory.deploy(signer.address);
    await souqNFTDiamond.deployed();
    const address = souqNFTDiamond.address
    console.log('souqNFTDiamond deployed to: ', souqNFTDiamond.address);

  ///////////////add facets to the souq NFT diamond
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
  ///////////////

  ///////////////Media deployment
  const mediaFacet = await hre.ethers.getContractAt(
    'MediaFacet',
    souqNFTDiamond.address,
  );
  await mediaFacet.mediaFacetInit(souqNFTDiamond.address, { gasLimit: 760000 });
 console.log('Media is initialized');
  ///////////////

///////////////token deployment
  const erc1155FactoryFacet = await hre.ethers.getContractAt(
    'ERC1155FactoryFacet',
    souqNFTDiamond.address,
  );
  const erc1155Name = 'NFT1155 SOUQ';
  const erc1155Symbol = 'NFT1155SOUQ';
  await erc1155FactoryFacet.erc1155FactoryFacetInit(erc1155Name, erc1155Symbol, { gasLimit: 760000 });
  console.log('erc1155FactoryFacet initialized');

  const erc721FactoryFacet = await hre.ethers.getContractAt(
    'ERC721FactoryFacet',
    souqNFTDiamond.address,
  );
  const erc721Name = 'NFT721 SOUQ';
  const erc721Symbol = 'NFT721SOUQ';
  await erc721FactoryFacet.erc721FactoryFacetInit(erc721Name, erc721Symbol, { gasLimit: 760000 });
  console.log('erc721FactoryFacet initialized');
  ///////////////


  ///////////////Market deployment
  const marketFacet = await hre.ethers.getContractAt(
    'MarketFacet',
    souqNFTDiamond.address,
  );

  const marketName = 'Marketplace';
  const marketVersion = '1.0.0';
  await marketFacet.marketFacetInit(marketName, marketVersion, { gasLimit: 760000 });
  console.log('MARKET is initialized');

  // const marketAddress = await marketFacet.getAddress();
  // console.log('Market IS initialized with address', marketAddress );
  ///////////////

  ///////////////Minting token from 721 contract
  const token721 = await mediaFacet.mintTokenMedia(
    signer.address,
    0,
    "ERC721",
    1,
    "12345",
    true,
    ["0x71593BAc0b4aE5278f784f0910f4829A103Ba7Cd", "0xCcd5FAA0C14641319f31eD72158d35BE6b9b90Da"],
    // [signer2.address, signer3.address],
    [500, 500],
    { gasLimit: 760000 }
  );

  // await mediaFacet.mintTokenMedia(
  //   signer1.address,
  //   1,
  //   "ERC721",
  //   1,
  //   "12345",
  //   true,
  //   [signer2.address],
  //   [50]
  // );

  console.log("Owner of 721 token 0", await erc721FactoryFacet.ownerOf(0))
  // console.log("Owner of 721 token 1", await erc721FactoryFacet.ownerOf(1))
  ///////////////

  //////royalty check for 1 eth
  const r = await erc721FactoryFacet.royaltyInfo721(0, ethers.utils.parseEther('1.0'))
   console.log("royality address of tokenId 0 is : ", r[0])
   console.log("royality share for first account 1 eth is  : ", ethers.utils.formatEther(r[1][0]))
   console.log("royality share for second account 1 eth is  : ", ethers.utils.formatEther(r[1][1]))

   ///////////////

  ///////////////checking toekn exists or not from media
  console.log("Token number 0 of 721 exists: ", await mediaFacet.istokenIdExistMedia(0,"ERC721"));
  ///////////////

  ///////////////set approved erc20 tokens from media
  await mediaFacet.connect(signer).setApprovedCryptoMedia(
    "0xc778417E063141139Fce010982780140Aa0cD5Ab",
    true,
    { gasLimit: 760000 }
    );

  //console.log("Mock token is approved: ", await mediaFacet.getApprovedCryptoMedia(erc20Address));
  ///////////////

  ///////////////set platform commission fee from media
  await mediaFacet.connect(signer).setCommissionPercentageMedia(250,{ gasLimit: 760000 });
  console.log("Platform commission fee: ", parseInt(await mediaFacet.getAdminCommissionPercentageMedia()));
  ///////////////

  /////////////// set collabortors from media
  await mediaFacet.connect(signer).setCollaboratorsMedia(
    souqNFTDiamond.address,
    0,
    ["0xa17C8DEbd6b9c2E993862255B992d45011dc898b", "0x71593BAc0b4aE5278f784f0910f4829A103Ba7Cd"],
    [1000,1000],
    { gasLimit: 760000 }
    );

  // await mediaFacet.connect(signer1).setCollaboratorsMedia(
  //   souqNFTDiamond.address,
  //   1,
  //   [signer2.address, signer3.address],
  //   [100,100]
  //   );

  const collabTarget0 = await mediaFacet.getCollaboratorsMedia(souqNFTDiamond.address, 0); 
  // const collabTarget1 = await mediaFacet.getCollaboratorsMedia(souqNFTDiamond.address, 1); 

  console.log("Collaborators of token0 are ",  collabTarget0 ) 
  console.log("Shares of token0 are ", (collabTarget0["collabFraction"])) 
  ///////////////


  //// Minting erc721 mock token

  // const ERC721Mock = await hre.ethers.getContractFactory(
  //   'ERC721Mock',
  // );
  // const erc721Mock = await ERC721Mock.deploy("TestNFT", "TNFT",true,[signer1.address],[1000]);
  // await erc721Mock.deployed();
  // await erc721Mock.safeMint(signer1.address,0,false,[signer1.address],[0]);
  // const erc721Address = erc721Mock.address
  // console.log('The balance of signer1 is: ',  parseInt(await erc721Mock.balanceOf(signer1.address)))

  // await erc721Mock.connect(signer1).setApprovalForAll(address, true);
  // console.log('Media is approved for all mock 721 tokens: ',  await erc721Mock.isApprovedForAll(signer1.address, address))

///////////////////////////////////////


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });