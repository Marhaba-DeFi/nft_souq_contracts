const hre = require('hardhat');
const ethers = hre.ethers;

function convertToBigNumber (val) {
  return ethers.utils.parseEther(val.toString()).toString();
}
function convertFromBigNumber (val) {
  return ethers.utils.formatEther(val.toString()).toString();
}

function convertToBN (val) {
  return ethers.utils.parseUnits(val, 18);
}

function covertFromBN (val) {
  return ethers.utils.formatUnits(val, 18);
}

module.exports = {
  convertFromBigNumber,
  convertToBigNumber,
  convertToBN,
  covertFromBN,
};
