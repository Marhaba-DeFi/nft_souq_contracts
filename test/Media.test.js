// We import Chai to use its asserting functions here.
const { expect } = require('chai')
// const { ethers } = require('ethers')
const hre = require('hardhat')
const ethers = hre.ethers
let deployer
// `describe` is a Mocha function that allows you to organize your tests. It's
// not actually needed, but having your tests organized makes debugging them
// easier. All Mocha functions are available in the global scope.

// `describe` receives the name of a section of your test suite, and a callback.
// The callback must define the tests of that section. This callback can't be
// an async function.
describe('Media Contract', async function () {
  before(async function () {
    this.signers = await ethers.getSigners()
    console.log('this.signer.length ', this.signers.length)
    this.deployer = this.signers[0]
    this.admin = this.signers[1]
    this.ERC20Mock = await ethers.getContractFactory('ERC20Mock', this.deployer)
    this.alice = this.signers[2]
    this.bob = this.signers[3]
    this.carol = this.signers[4]
  })

  // `beforeEach` will run before each test, re-deploying the contract every
  // time. It receives a callback, which can be async.
  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    const erc721Name = 'NFT SOUQ'
    const erc721Symbol = 'NFTSOUQ'
    const adminCommissionPercentage = 2

    this.erc721 = await ethers.getContractFactory('ERC721Factory')
    this.erc721 = await this.erc721.deploy(erc721Name, erc721Symbol)

    await this.erc721.deployed()

    // console.log('erc721 Token deployed at:', this.erc721.address)

    const erc1155Name = 'NFT SOUQ'
    const erc1155Symbol = 'NFTSOUQ'

    this.erc1155 = await hre.ethers.getContractFactory('ERC1155Factory')
    // erc1155 = await erc1155.deploy(erc1155Uri)
    this.erc1155 = await this.erc1155.deploy(erc1155Name, erc1155Symbol)

    await this.erc1155.deployed()

    // console.log('erc1155 Token deployed at:', this.erc1155.address)

    this.market = await hre.ethers.getContractFactory('Market')
    this.market = await this.market.deploy()

    await this.market.deployed()

    // console.log('Market deployed at:', this.market.address)

    this.media = await hre.ethers.getContractFactory('Media')
    this.media = await this.media.deploy(this.erc1155.address, this.erc721.address, this.market.address)

    await this.media.deployed()

    // console.log('media deployed at:', this.media.address)

    await this.market.configureMedia(this.media.address)
    // console.log('Configure Media address In market')

    await this.erc1155.configureMedia(this.media.address)
    await this.erc721.configureMedia(this.media.address)

    // console.log('Media Added In ERC')

    await this.media.setAdminAddress(this.admin.address)
    // console.log('configured admin address')

    await this.media.connect(this.admin).setCommissionPercentage(adminCommissionPercentage)
    // console.log('configured Commission Percentage address')
  })
  it('It should Mint NFT for user', async function () {
    console.log('Minter Started')
    let tx = await this.media.connect(this.alice).mintToken([
      0, // isFungible
      'QmTw4wfzNam6Rom59uhPjoxbarXi4oJrfzKp8Xr3nfWsr3', // IPFS hash
      'langs nft', // title
      '1', // totalSupply
      '0', // royaltyPoints
      ['0x4281d6888D7a3A6736B0F596823810ffBd7D4808'], // collaborators
      ['100'], // percentages
      '1', // askType  AUCTION - 0 , FIXED - 1
      '1', // _askAmount
      '1', // _reserveAmount
      '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd', // currencyAsked
    ])
    tx = await tx.wait() // 0ms, as tx is already confirmed
    const event = tx.events.find((event) => event.event === 'TokenCounter')
    const [_tokenCounter] = event.args
    expect(_tokenCounter.toString()).to.equals('1')
  })

  context('With ERC/LP token added to the field', function () {
    console.log('Tokens sent to the users account')
    beforeEach(async function () {
      this.marhabaToken = await this.ERC20Mock.deploy('Marhaba', 'MRHB', '10000000000')

      await this.marhabaToken.transfer(this.alice.address, '1000')

      await this.marhabaToken.transfer(this.bob.address, '1000')

      await this.marhabaToken.transfer(this.carol.address, '1000')

      this.wrapperToken = await this.ERC20Mock.deploy('Wrapper BNB', 'WBNB', '10000000000')

      await this.wrapperToken.transfer(this.alice.address, '1000')

      await this.wrapperToken.transfer(this.bob.address, '1000')

      await this.wrapperToken.transfer(this.carol.address, '1000')
    })
    it('Buy ERC721 NFT', async function () {
      let mintTx = await this.media.connect(this.alice).mintToken([
        false, // isFungible
        'QmTw4wfzNam6Rom59uhPjoxbarXi4oJrfzKp8Xr3nfWsr3', // IPFS hash
        'langs nft', // title
        '1', // totalSupply
        '0', // royaltyPoints
        ['0x4281d6888D7a3A6736B0F596823810ffBd7D4808'], // collaborators
        ['0'], // percentages
        '1', // askType  AUCTION - 0 , FIXED - 1
        '1', // _askAmount
        '1', // _reserveAmount
        this.marhabaToken.address, // currencyAsked
      ])
      console.log('Buy NFT minted')
      mintTx = await mintTx.wait() // 0ms, as tx is already confirmed
      const event = mintTx.events.find((event) => event.event === 'TokenCounter')
      const [_tokenCounter] = event.args
      expect(_tokenCounter.toString()).to.equals('1')
      // approve tokens before making request
      await this.marhabaToken.connect(this.bob).approve(this.market.address, '1000')
      await this.media.connect(this.bob).setBid(parseInt(_tokenCounter), [
        1, // quantity of the tokens being bid
        1, // amount of ERC20 token being used to bid
        this.marhabaToken.address, // Address to the ERC20 token being used to bid,
        this.bob.address, // bidder address
        this.bob.address, // recipient address
      ])
      expect((await this.marhabaToken.balanceOf(this.bob.address)).toString()).to.equal('999')
    })
    it('Buy 1155 NFT', async function () {
      let mintTx = await this.media.connect(this.alice).mintToken([
        true, // isFungible
        'QmTw4wfzNam6Rom59uhPjoxbarXi4oJrfzKp8Xr3nfWsr3', // IPFS hash
        'langs nft', // title
        '2', // totalSupply
        '0', // royaltyPoints
        ['0x4281d6888D7a3A6736B0F596823810ffBd7D4808'], // collaborators
        ['0'], // percentages
        '1', // askType  AUCTION - 0 , FIXED - 1
        '1', // _askAmount
        '1', // _reserveAmount
        this.marhabaToken.address, // currencyAsked
      ])
      console.log('Buy NFT minted')
      mintTx = await mintTx.wait() // 0ms, as tx is already confirmed
      const event = mintTx.events.find((event) => event.event === 'TokenCounter')
      const [_tokenCounter] = event.args
      expect(_tokenCounter.toString()).to.equals('1')
      // approve tokens before making request
      await this.marhabaToken.connect(this.bob).approve(this.market.address, '1000')
      await this.media.connect(this.bob).setBid(_tokenCounter, [
        1, // quantity of the tokens being bid
        100, // amount of ERC20 token being used to bid
        this.marhabaToken.address, // Address to the ERC20 token being used to bid,
        this.bob.address, // bidder address
        this.bob.address, // recipient address
      ])
      console.log('this.bob.address ', this.bob.address)
      console.log(await this.media.nftToOwners(_tokenCounter))
      expect((await this.marhabaToken.balanceOf(this.bob.address)).toString()).to.equal('999')
    })
  })
})
