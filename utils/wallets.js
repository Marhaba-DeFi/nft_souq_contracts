const hre = require('hardhat')
const ethers = hre.ethers
// const ethers = require('ethers')
const privateKeys = [
  '0x5f4445ba69d36a98174d0d4584b2e663ae35dd570dfdca63639fda511ad76b5c',
  '0x1deb83a0b24016f1d0de84963a3c60ceff6a7c08dcebefc5e40ac92247848b65',
  '0xedff6515810c1d72ca2c7ad9ae1af24605781cc7e5336a560bcb0a66685ce241',
  '0x0c6c17ad938e3a9fd1a76c822fbb00427845116253c30ea1d84ab731393cfbaa',
]

function generatedWallets(provider) {
  return privateKeys.map((key) => {
    return new ethers.Wallet(key, provider)
  })
}

module.exports = {
  generatedWallets,
}
