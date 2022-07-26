// utils
const hre = require('hardhat');
const { updateContractAddresses } = require('../utils/contractsManagement');

// const provider = new ethers.getDefaultProvider(process.env.NETWORK);
const network = hre.hardhatArguments.network;
async function main() {
  const erc721Name = 'NFT SOUQ';
  const erc1155Name = 'NFT SOUQ 1155';
  const sbtName = 'NFT SOUQ SBT';
  const version = 'V-0.1';
  const symbol = 'SOUQ';
  const erc1155symbol = 'SOUQ 1155';
  const sbtSymbol = 'SOUQ SBT';
  const royaltyFees = 50;

  const accounts = await hre.ethers.getSigners();

  // deploying Media contract
  const media = await hre.ethers.getContractFactory('Media');
  const deployedMedia = await media.deploy();
  await deployedMedia.deployed();
  console.log('Souq Media is deployed at ', deployedMedia.address);

  // deploying the souq NFT Market
  const souqMarket = await hre.ethers.getContractFactory('SouqMarketPlace');
  const deployedSouqMarket = await souqMarket.deploy(erc721Name, version);
  await deployedSouqMarket.deployed();
  console.log('Souq market is deployed at ', deployedSouqMarket.address);

  // deploying the ERC721A Factory
  const erc721a = await hre.ethers.getContractFactory('ERC721AFactory');
  const deployedErc721a = await erc721a.deploy(
    erc721Name,
    symbol,
    royaltyFees,
    accounts[0].address,
  );
  await deployedErc721a.deployed();
  console.log('ERC721A Factory is deployed at ', deployedErc721a.address);

  // deploying the ERC721 Factory
  const erc721 = await hre.ethers.getContractFactory('SouqERC721');
  const deployedErc721 = await erc721.deploy(
    erc721Name,
    symbol,
    accounts[0].address,
    royaltyFees,
  );
  await deployedErc721.deployed();
  console.log('ERC721 Factory is deployed at ', deployedErc721.address);

  // deploying the ERC1155 Factory
  const erc1155 = await hre.ethers.getContractFactory('Souq1155');
  const deployedErc1155 = await erc1155.deploy(
    erc1155Name,
    erc1155symbol,
    royaltyFees,
    accounts[0].address,
  );
  await deployedErc1155.deployed();
  console.log('ERC1155 Factory is deployed at ', deployedErc1155.address);

  // deploying the SBT Factory
  const sbt = await hre.ethers.getContractFactory('SBTFactory');
  const sbtFactory = await sbt.deploy(sbtName, sbtSymbol);
  await sbtFactory.deployed();
  console.log('SBT Factory is deployed at ', sbtFactory.address);

  // configuring Media for other contracts

  // configuring Media for market
  await deployedSouqMarket.configureMedia(deployedMedia.address);
  console.log('Media configured for Market');

  // configuring Market for Media 
  await deployedMedia.configureMarketPlace(deployedSouqMarket.address);
  console.log("Market configured for Media"); 

  // configuring Media for ERC721A Factory
  await deployedErc721a.configureMedia(deployedMedia.address);
  console.log('Media configured for ERC721A Factory');

  // configuring Media for ERC721 Factory
  await deployedErc721.configureMedia(deployedMedia.address);
  console.log('Media configured for ERC721 Factory');

  // configuring Media for ERC1155 Factory
  await deployedErc1155.configureMedia(deployedMedia.address);
  console.log('Media configured for ERC1155 Factory');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
