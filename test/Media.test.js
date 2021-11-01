// We import Chai to use its asserting functions here.
const { expect } = require('chai')
// const { ethers } = require('ethers')
const hre = require('hardhat')
const ethers = hre.ethers
const { convertToBigNumber, convertFromBigNumber } = require('../utils/utils')
const { generatedWallets } = require('../utils/wallets')
const { JsonRpcProvider } = require('@ethersproject/providers')

// `describe` is a Mocha function that allows you to organize your tests. It's
// not actually needed, but having your tests organized makes debugging them
// easier. All Mocha functions are available in the global scope.

// `describe` receives the name of a section of your test suite, and a callback.
// The callback must define the tests of that section. This callback can't be
// an async function.

const network = process.argv[4]
describe('Media Contract', async function () {
  before(async function () {
    let provider = new JsonRpcProvider(process.env.PROVIDER_URL)

    this.signers = network ? generatedWallets(provider) : await ethers.getSigners()
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
    this.ERC20Mock = await ethers.getContractFactory('ERC20Mock')
    let erc721 = await hre.ethers.getContractFactory('ERC721Factory')
    let erc1155 = await hre.ethers.getContractFactory('ERC1155Factory')
    let market = await hre.ethers.getContractFactory('Market')
    let media = await hre.ethers.getContractFactory('Media')
    // this.erc721 = await erc721.attach('0xE3F1fe1c936eA0532abbB194EADa1618D0a92A01')
    // this.erc1155 = await erc1155.attach('0xB29aaEEab8145145D6df72fAA269f5d8B0700a13')
    // this.market = await market.attach('0xB337015fba42D497C298DDde1a7c822A78677B30')
    // this.media = await media.attach('0x8713C75a8192E9Ec0992a6eb3ea1626c5B0230fC')
    // // 0x45202955b5a2770A4dc526B6FB3634dDB275c8Df BSC
    // // 0xf865baC31648eb5d5BB67f954664734D870405Bf kovan
    // // this.marhabaToken = this.ERC20Mock.attach('0xf865baC31648eb5d5BB67f954664734D870405Bf')

    // // Get the ContractFactory and Signers here.
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
    console.log('Media Added In ERC')
    await this.media.setAdminAddress(this.admin.address)
    // console.log('configured admin address')
    await this.media.connect(this.admin).setCommissionPercentage(adminCommissionPercentage)
    console.log('configured Commission Percentage address')
  })
  context('With ERC/LP token added to the field', function () {
    beforeEach(async function () {
      // variables for maintaining Bid
      this.ipfsHash = 'QmTw4wfzNam6Rom59uhPjoxbarXi4oJrfzKp8Xr3nfWsr3'
      this.title = 'My Langs NFT'
      this.totalSupply = 1
      this.royaltyPoints = 5
      this.collabsAddresses = ['0x0000000000000000000000000000000000000000']
      this.collabsPercentages = [0]
      this.auctionType = 1 // askType  AUCTION - 0 , FIXED - 1
      this.askAmount = convertToBigNumber(5)
      this.reserveAmount = convertToBigNumber(5)
      // variables for maintaining asks
      this.askReserveAmount = 4
      this.askMaxAmount = 4
      this.duration = parseInt(Date.now() + 86400)
      console.log(this.deployer.address, this.admin.address, this.alice.address, this.bob.address)

      // * Math.pow(10, 18)
      const totalSupply = 10000000000
      this.marhabaToken = await this.ERC20Mock.deploy('Marhaba', 'MRHB', convertToBigNumber(totalSupply))

      // console.log((await this.marhabaToken.balanceOf(this.deployer.address)).toString())

      await this.marhabaToken.transfer(this.alice.address, convertToBigNumber(1000))

      await this.marhabaToken.transfer(this.bob.address, convertToBigNumber(1000))

      // await this.marhabaToken.transfer(this.carol.address, convertToBigNumber(1000))

      this.wrapperToken = await this.ERC20Mock.deploy('Wrapper BNB', 'WBNB', convertToBigNumber(totalSupply))

      await this.wrapperToken.transfer(this.alice.address, convertToBigNumber(1000))

      await this.wrapperToken.transfer(this.bob.address, convertToBigNumber(1000))

      // await this.wrapperToken.transfer(this.carol.address, convertToBigNumber(1000))
    })
    it('It should Mint NFT for user', async function () {
      let tx = await this.media.connect(this.alice).mintToken([
        this.ipfsHash, // IPFS hash
        this.title, // title
        this.totalSupply, // totalSupply
        this.royaltyPoints, // royaltyPoints
        this.collabsAddresses, // collaborators
        this.collabsPercentages, // percentages
        this.auctionType, // askType  AUCTION - 0 , FIXED - 1
        this.askAmount, // _askAmount
        this.reserveAmount, // _reserveAmount
        this.marhabaToken.address, // currencyAsked
        this.duration, // Auction End Time
      ])
      tx = await tx.wait() // 0ms, as tx is already confirmed
      const event = tx.events.find((event) => event.event === 'TokenCounter')
      const [_tokenCounter] = event.args
      expect(_tokenCounter.toString()).to.equals('1')
    })
    it('Buy ERC721 NFT without collabs', async function () {
      let mintTx = await this.media.connect(this.alice).mintToken([
        this.ipfsHash, // IPFS hash
        this.title, // title
        this.totalSupply, // totalSupply
        this.royaltyPoints, // royaltyPoints
        this.collabsAddresses, // collaborators
        this.collabsPercentages, // percentages
        this.auctionType, // askType  AUCTION - 0 , FIXED - 1
        this.askAmount, // _askAmount
        this.reserveAmount, // _reserveAmount
        this.marhabaToken.address, // currencyAsked
        this.duration, // Auction End Time
      ])
      mintTx = await mintTx.wait() // 0ms, as tx is already confirmed
      const event = mintTx.events.find((event) => event.event === 'TokenCounter')
      const [_tokenCounter] = event.args
      expect(_tokenCounter.toString()).to.equals('1')
      console.log('token minted with id ', _tokenCounter.toString())

      // approve tokens before making request
      await this.marhabaToken.connect(this.bob).approve(this.market.address, convertToBigNumber(1000))

      await this.media.connect(this.bob).setBid(
        _tokenCounter, // _tokenCounter.toString(),
        [
          1, // quantity of the tokens being bid
          convertToBigNumber(5), // amount of ERC20 token being used to bid
          this.marhabaToken.address, // Address to the ERC20 token being used to bid,
          this.bob.address, // bidder address
          this.bob.address, // recipient address
        ],
        { from: this.bob.address }
      )
      const aliceBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.alice.address))
      const bobBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.bob.address))
      const collabsBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.collabsAddresses[0]))
      const adminBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.admin.address))

      console.log('aliceBalance ', aliceBalance)
      console.log('bobBalance ', bobBalance)
      console.log('collabsBalance ', collabsBalance)
      console.log('adminBalance ', adminBalance)

      expect(_tokenCounter.toString()).to.equals('1')
      expect(aliceBalance).to.equals('1004.9')
      expect(bobBalance).to.equals('995.0')
      expect(collabsBalance).to.equals('0.0')
      expect(adminBalance).to.equals('0.1')
      expect(parseFloat(aliceBalance) + parseFloat(bobBalance)).to.equals(1999.9)
    })
    it('Buy ERC721 NFT with collabs', async function () {
      this.collabsAddresses = ['0x42eb768f2244c8811c63729a21a3569731535f06']
      this.collabsPercentages = [10]
      this.askAmount = convertToBigNumber(5)
      this.reserveAmount = convertToBigNumber(5)

      let mintTx = await this.media.connect(this.alice).mintToken([
        this.ipfsHash, // IPFS hash
        this.title, // title
        this.totalSupply, // totalSupply
        this.royaltyPoints, // royaltyPoints
        this.collabsAddresses, // collaborators
        this.collabsPercentages, // percentages
        this.auctionType, // askType  AUCTION - 0 , FIXED - 1
        this.askAmount, // _askAmount
        this.reserveAmount, // _reserveAmount
        this.marhabaToken.address, // currencyAsked
        this.duration, // Auction End Time
      ])
      mintTx = await mintTx.wait() // 0ms, as tx is already confirmed
      const event = mintTx.events.find((event) => event.event === 'TokenCounter')
      const [_tokenCounter] = event.args
      expect(_tokenCounter.toString()).to.equals('1')

      // approve tokens before making request
      await this.marhabaToken.connect(this.bob).approve(this.market.address, convertToBigNumber(1000))

      await this.media.connect(this.bob).setBid(
        1, // _tokenCounter.toString(),
        [
          1, // quantity of the tokens being bid
          convertToBigNumber(5), // amount of ERC20 token being used to bid
          this.marhabaToken.address, // Address to the ERC20 token being used to bid,
          this.bob.address, // bidder address
          this.bob.address, // recipient address
        ],
        { from: this.bob.address }
      )
      const aliceBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.alice.address))
      const bobBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.bob.address))
      const collabsBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.collabsAddresses[0]))
      const adminBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.admin.address))

      console.log('aliceBalance ', aliceBalance)
      console.log('bobBalance ', bobBalance)
      console.log('collabsBalance ', collabsBalance)
      console.log('adminBalance ', adminBalance)

      expect(_tokenCounter.toString()).to.equals('1')
      expect(aliceBalance).to.equals('1004.8755')
      expect(bobBalance).to.equals('995.0')
      expect(collabsBalance).to.equals('0.0245')
      expect(adminBalance).to.equals('0.1')
      expect(parseFloat(aliceBalance) + parseFloat(collabsBalance) + parseFloat(adminBalance)).to.equals(1005)
    })

    it('Buy 1155 NFT without collabs', async function () {
      this.askAmount = convertToBigNumber(3)
      this.reserveAmount = convertToBigNumber(3)
      this.totalSupply = 5
      this.ipfsHash = 'generaterandom234234444'
      let mintTx = await this.media.connect(this.alice).mintToken([
        this.ipfsHash, // IPFS hash
        this.title, // title
        this.totalSupply, // totalSupply
        this.royaltyPoints, // royaltyPoints
        this.collabsAddresses, // collaborators
        this.collabsPercentages, // percentages
        this.auctionType, // askType  AUCTION - 0 , FIXED - 1
        this.askAmount, // _askAmount
        this.reserveAmount, // _reserveAmount
        this.marhabaToken.address, // currencyAsked
        this.duration, // Auction End Time
      ])
      mintTx = await mintTx.wait() // 0ms, as tx is already confirmed
      const event = mintTx.events.find((event) => event.event === 'TokenCounter')
      const [_tokenCounter] = event.args
      expect(_tokenCounter.toString()).to.equals('1')

      // approve tokens before making request
      await this.marhabaToken.connect(this.bob).approve(this.market.address, convertToBigNumber(1000))

      await this.media.connect(this.bob).setBid(
        _tokenCounter, // _tokenCounter.toString(),
        [
          2, // quantity of the tokens being bid
          convertToBigNumber(3), // amount of ERC20 token being used to bid
          this.marhabaToken.address, // Address to the ERC20 token being used to bid,
          this.bob.address, // bidder address
          this.bob.address, // recipient address
        ],
        { from: this.bob.address }
      )
      const aliceBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.alice.address))
      const bobBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.bob.address))
      const collabsBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.collabsAddresses[0]))
      const adminBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.admin.address))

      console.log('aliceBalance ', aliceBalance)
      console.log('bobBalance ', bobBalance)
      console.log('collabsBalance ', collabsBalance)
      console.log('adminBalance ', adminBalance)

      expect(_tokenCounter.toString()).to.equals('1')
      expect(aliceBalance).to.equals('1002.94')
      expect(bobBalance).to.equals('997.0')
      expect(collabsBalance).to.equals('0.0')
      expect(adminBalance).to.equals('0.06')
      expect(parseFloat(aliceBalance) + parseFloat(bobBalance)).to.equals(1999.94)
    })
    it('Should Fail Again Buy, Sold 1155 NFT without collabs', async function () {
      this.askAmount = convertToBigNumber(3)
      this.reserveAmount = convertToBigNumber(3)
      this.totalSupply = 5
      this.ipfsHash = 'generaterandom234234444'
      let mintTx = await this.media.connect(this.alice).mintToken([
        this.ipfsHash, // IPFS hash
        this.title, // title
        this.totalSupply, // totalSupply
        this.royaltyPoints, // royaltyPoints
        this.collabsAddresses, // collaborators
        this.collabsPercentages, // percentages
        this.auctionType, // askType  AUCTION - 0 , FIXED - 1
        this.askAmount, // _askAmount
        this.reserveAmount, // _reserveAmount
        this.marhabaToken.address, // currencyAsked
        this.duration, // Auction End Time
      ])
      mintTx = await mintTx.wait() // 0ms, as tx is already confirmed
      const event = mintTx.events.find((event) => event.event === 'TokenCounter')
      const [_tokenCounter] = event.args
      expect(_tokenCounter.toString()).to.equals('1')

      // approve tokens before making request
      await this.marhabaToken.connect(this.bob).approve(this.market.address, convertToBigNumber(1000))

      await this.media.connect(this.bob).setBid(
        _tokenCounter, // _tokenCounter.toString(),
        [
          2, // quantity of the tokens being bid
          convertToBigNumber(3), // amount of ERC20 token being used to bid
          this.marhabaToken.address, // Address to the ERC20 token being used to bid,
          this.bob.address, // bidder address
          this.bob.address, // recipient address
        ],
        { from: this.bob.address }
      )
      const aliceBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.alice.address))
      const bobBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.bob.address))
      const collabsBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.collabsAddresses[0]))
      const adminBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.admin.address))

      console.log('aliceBalance ', aliceBalance)
      console.log('bobBalance ', bobBalance)
      console.log('collabsBalance ', collabsBalance)
      console.log('adminBalance ', adminBalance)

      expect(_tokenCounter.toString()).to.equals('1')
      expect(aliceBalance).to.equals('1002.94')
      expect(bobBalance).to.equals('997.0')
      expect(collabsBalance).to.equals('0.0')
      expect(adminBalance).to.equals('0.06')
      expect(parseFloat(aliceBalance) + parseFloat(bobBalance)).to.equals(1999.94)
      // Bought again request

      await expect(
        this.media.connect(this.alice).setBid(
          _tokenCounter, // _tokenCounter.toString(),
          [
            2, // quantity of the tokens being bid
            convertToBigNumber(3), // amount of ERC20 token being used to bid
            this.marhabaToken.address, // Address to the ERC20 token being used to bid,
            this.alice.address, // bidder address
            this.alice.address, // recipient address
          ],
          { from: this.alice.address }
        )
      ).to.be.revertedWith('Token is not open for Sale')
    })
    it('Should Pass Again Buy, Sold 1155 NFT without collabs', async function () {
      this.collabsAddresses = ['0x5CB88D82E01C6C6FeB89fA5021706b449ad0b303']
      this.collabsPercentages = [10]

      this.askAmount = convertToBigNumber(3)
      this.reserveAmount = convertToBigNumber(3)
      this.totalSupply = 5
      this.ipfsHash = 'generaterandom234234444'
      let mintTx = await this.media.connect(this.alice).mintToken([
        this.ipfsHash, // IPFS hash
        this.title, // title
        this.totalSupply, // totalSupply
        this.royaltyPoints, // royaltyPoints
        this.collabsAddresses, // collaborators
        this.collabsPercentages, // percentages
        this.auctionType, // askType  AUCTION - 0 , FIXED - 1
        this.askAmount, // _askAmount
        this.reserveAmount, // _reserveAmount
        this.marhabaToken.address, // currencyAsked
        this.duration, // Auction End Time
      ])
      mintTx = await mintTx.wait() // 0ms, as tx is already confirmed
      const event = mintTx.events.find((event) => event.event === 'TokenCounter')
      const [_tokenCounter] = event.args
      expect(_tokenCounter.toString()).to.equals('1')

      // approve tokens before making request
      await this.marhabaToken.connect(this.bob).approve(this.market.address, convertToBigNumber(1000))

      // console.log('ask detail before first bid ', await this.market._tokenAsks(_tokenCounter))
      await this.media.connect(this.bob).setBid(
        _tokenCounter, // _tokenCounter.toString(),
        [
          this.totalSupply, // quantity of the tokens being bid
          convertToBigNumber(3), // amount of ERC20 token being used to bid
          this.marhabaToken.address, // Address to the ERC20 token being used to bid,
          this.bob.address, // bidder address
          this.bob.address, // recipient address
        ],
        { from: this.bob.address }
      )
      // console.log('ask detail after first bid ', await this.market._tokenAsks(_tokenCounter))
      // console.log('tokenCollaborators after bid ', await this.market.tokenCollaborators(_tokenCounter))

      let aliceBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.alice.address))
      let bobBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.bob.address))
      let collabsBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.collabsAddresses[0]))
      let adminBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.admin.address))

      // console.log('aliceBalance ', aliceBalance)
      // console.log('bobBalance ', bobBalance)
      // console.log('collabsBalance ', collabsBalance)
      // console.log('adminBalance ', adminBalance)

      expect(_tokenCounter.toString()).to.equals('1')
      expect(aliceBalance).to.equals('1002.9253')
      expect(bobBalance).to.equals('997.0')
      expect(collabsBalance).to.equals('0.0147')
      expect(adminBalance).to.equals('0.06')
      expect(parseFloat(aliceBalance) + parseFloat(bobBalance)).to.equals(1999.9252999999999)
      // Bought again request

      await this.marhabaToken.connect(this.alice).approve(this.market.address, convertToBigNumber(1000))
      this.askAmount = convertToBigNumber(100)
      this.reserveAmount = convertToBigNumber(100)

      console.log('ask placed')
      await this.media
        .connect(this.bob)
        .setAsk(
          _tokenCounter,
          [
            this.askAmount,
            this.reserveAmount,
            this.totalSupply,
            this.marhabaToken.address,
            this.auctionType,
            0,
            0,
            this.collabsAddresses[0],
            0,
          ],
          {
            from: this.bob.address,
          }
        )
      // console.log('ask detail after first ask ', await this.market._tokenAsks(_tokenCounter))

      await this.media.connect(this.alice).setBid(
        _tokenCounter, // _tokenCounter.toString(),
        [
          this.totalSupply, // quantity of the tokens being bid
          convertToBigNumber(100), // amount of ERC20 token being used to bid
          this.marhabaToken.address, // Address to the ERC20 token being used to bid,
          this.alice.address, // bidder address
          this.alice.address, // recipient address
        ],
        { from: this.alice.address }
      )

      aliceBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.alice.address))
      bobBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.bob.address))
      collabsBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.collabsAddresses[0]))
      adminBalance = convertFromBigNumber(await this.marhabaToken.balanceOf(this.admin.address))

      console.log(aliceBalance, bobBalance, collabsBalance, adminBalance)
      expect(aliceBalance).to.equals('907.8253')
      expect(bobBalance).to.equals('1090.1')
      expect(collabsBalance).to.equals('0.0147')
      expect(adminBalance).to.equals('2.06')
      expect(parseFloat(aliceBalance) + parseFloat(bobBalance) + parseFloat(adminBalance)).to.equals(1999.9852999999998)
    })
  })
})
