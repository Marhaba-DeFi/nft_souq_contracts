const { convertToBigNumber } = require('../utils/util');
const randomString = require('randomstring');
const { generatedWallets } = require('../utils/wallets');
const { JsonRpcProvider } = require('@ethersproject/providers');
const ethers = require('ethers');

const mintObject = {
  ipfsHash: randomString.generate({
    length: 10,
    charset: 'numeric',
  }),
  title: 'My Langs NFT',
  totalSupply: 1,
  royaltyPoints: 5,
  collabsAddresses: ['0x0000000000000000000000000000000000000000'],
  collabsPercentages: [0],
  auctionType: 1, // askType  AUCTION - 0 , FIXED - 1
  askAmount: convertToBigNumber(5),
  reserveAmount: convertToBigNumber(5),
  askReserveAmount: 4,
  askMaxAmount: 4,
  duration: parseInt(Date.now() + 86400),
};

const mintArray = [
  mintObject.ipfsHash, // IPFS hash
  mintObject.title, // title
  mintObject.totalSupply, // totalSupply
  mintObject.royaltyPoints, // royaltyPoints
  mintObject.collabsAddresses, // collaborators
  mintObject.collabsPercentages, // percentages
  mintObject.auctionType, // askType  AUCTION - 0 , FIXED - 1
  mintObject.askAmount, // _askAmount
  mintObject.reserveAmount, // _reserveAmount
  '0x0000000000000000000000000000000000000000',
  mintObject.duration, // Auction End Time
];
async function getProvider () {
  console.log(process.env.PROVIDER_URL);
  return new JsonRpcProvider(process.env.PROVIDER_URL);
}
async function getWalletsMappings (network) {
  const provider = await getProvider();
  const signer = network === 'test' ? await ethers.getSigners() : generatedWallets(provider);
  return {
    deployer: signer[0],
    admin: signer[1],
    alice: signer[2],
    bob: signer[3],
  };
}
module.exports = {
  mintObject,
  mintArray,
  getProvider,
  getWalletsMappings,
};
