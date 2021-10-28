// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat')
const ethers = hre.ethers
const { convertToBigNumber } = require('../utils/utils')
const provider = new ethers.getDefaultProvider(process.env.NETWORK)

async function main() {
  let token = await hre.ethers.getContractFactory('ERC20Mock')
  token = await token.deploy('MARHABA', 'MRHB', convertToBigNumber(100000))

  await token.deployed()

  console.log('Token deployed at:', token.address)
  await token.transfer('0xD68fdc0B89010a9039C2C38f4a3E5c4Ed98f7bC1', convertToBigNumber(1000))
  await token.transfer('0x498F630f8A547D38f0B95141e4789560c5cEf27C', convertToBigNumber(1000))
  await token.transfer('0x78665B237158510C68Fe71AD110B5eee6cD5d7B0', convertToBigNumber(1000))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
