// utils
const hre = require('hardhat');
const { FacetCutAction, getSelectors } = require('../utils/diamond');

async function main() {
  const diamondAddress = '';

  // deploying the souq NFT diamond
  const souqNFTDiamond = await hre.ethers.getContractAt(
    'SouqNFTDiamond', diamondAddress,
  );

  const cut = [];

  souqNFTDiamond.diamondCut(cut, hre.ethers.constants.AddressZero, '0x');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
