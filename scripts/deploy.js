// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat')
const ethers = hre.ethers

const provider = new ethers.getDefaultProvider(process.env.NETWORK)

async function main() {
  const erc721Name = 'NFT SOUQ'
  const erc721Symbol = 'NFTSOUQ'
  const adminAddress = '0x4281d6888D7a3A6736B0F596823810ffBd7D4808'
  const adminCommissionPercentage = '1'

  let erc721 = await hre.ethers.getContractFactory('ERC721Factory')
  erc721 = await erc721.deploy(erc721Name, erc721Symbol)

  await erc721.deployed()

  console.log('erc721 Token deployed at:', erc721.address)

  const erc1155Uri = ''
  const erc1155Name = 'NFT SOUQ'
  const erc1155Symbol = 'NFTSOUQ'
  let erc1155 = await hre.ethers.getContractFactory('ERC1155Factory')
  // erc1155 = await erc1155.deploy(erc1155Uri)
  erc1155 = await erc1155.deploy(erc1155Name, erc1155Symbol)

  await erc1155.deployed()

  console.log('erc1155 Token deployed at:', erc1155.address)

  let market = await hre.ethers.getContractFactory('Market')
  market = await market.deploy()

  await market.deployed()

  console.log('Market deployed at:', market.address)

  let media = await hre.ethers.getContractFactory('Media')
  media = await media.deploy(erc1155.address, erc721.address, market.address)

  await media.deployed()

  console.log('media deployed at:', media.address)

  await market.configureMedia(media.address)
  console.log('Configure Media address In market')

  await erc1155.configureMedia(media.address)
  await erc721.configureMedia(media.address)

  console.log('Media Added In ERC')

  await media.setAdminAddress(adminAddress)
  console.log('configured admin address')

  await media.setCommissionPercentage(adminCommissionPercentage)
  console.log('configured Commission Percentage address')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
