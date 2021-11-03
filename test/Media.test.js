// We import Chai to use its asserting functions here.
const { expect } = require('chai');
const fs = require('fs');
const hre = require('hardhat');
const ethers = hre.ethers;
const { convertToBigNumber } = require('../utils/util');
const { generatedWallets } = require('../utils/wallets');
const { mintObject } = require('./Media.Objects');
const { JsonRpcProvider } = require('@ethersproject/providers');
const path = require('path');

const {
  mintTokens,
  fetchMintEvent,
  approveTokens,
  setBid,
  getBalance,
} = require('./Media.helper');
// `describe` is a Mocha function that allows you to organize your tests. It's
// not actually needed, but having your tests organized makes debugging them
// easier. All Mocha functions are available in the global scope.

// `describe` receives the name of a section of your test suite, and a callback.
// The callback must define the tests of that section. This callback can't be
// an async function.

const network = process.argv[4];
describe('Media Contract', async function () {
  before(async function () {
    const provider = new JsonRpcProvider(process.env.PROVIDER_URL);

    this.signers = network
      ? generatedWallets(provider)
      : await ethers.getSigners();
    this.deployer = this.signers[0];
    this.admin = this.signers[1];
    this.alice = this.signers[2];
    this.bob = this.signers[3];
    this.carol = this.signers[4];
  });

  // `beforeEach` will run before each test, re-deploying the contract every
  // time. It receives a callback, which can be async.
  beforeEach(async function () {
    if (network) {
      const contractAddresses = JSON.parse(
        fs.readFileSync(path.resolve(__dirname, '../config.json'), 'utf8'),
      );
      const erc721 = await hre.ethers.getContractFactory('ERC721Factory');
      const erc1155 = await hre.ethers.getContractFactory('ERC1155Factory');
      const market = await hre.ethers.getContractFactory('Market');
      const media = await hre.ethers.getContractFactory('Media');
      this.erc721 = await erc721.attach(contractAddresses[network].ERC721);
      this.erc1155 = await erc1155.attach(contractAddresses[network].ERC1155);
      this.market = await market.attach(contractAddresses[network].MARKET);
      this.media = await media.attach(contractAddresses[network].MEDIA);
      // 0x45202955b5a2770A4dc526B6FB3634dDB275c8Df BSC
      // 0xf865baC31648eb5d5BB67f954664734D870405Bf kovan
      this.marhabaToken = this.ERC20Mock.attach('0x45202955b5a2770A4dc526B6FB3634dDB275c8Df');
    } else {
      this.ERC20Mock = await ethers.getContractFactory('ERC20Mock');

      // // Get the ContractFactory and Signers here.
      const erc721Name = 'NFT SOUQ';
      const erc721Symbol = 'NFTSOUQ';
      const adminCommissionPercentage = 2;
      this.erc721 = await ethers.getContractFactory('ERC721Factory');
      this.erc721 = await this.erc721.deploy(erc721Name, erc721Symbol);
      await this.erc721.deployed();
      // console.log('erc721 Token deployed at:', this.erc721.address)
      const erc1155Name = 'NFT SOUQ';
      const erc1155Symbol = 'NFTSOUQ';
      this.erc1155 = await hre.ethers.getContractFactory('ERC1155Factory');
      // erc1155 = await erc1155.deploy(erc1155Uri)
      this.erc1155 = await this.erc1155.deploy(erc1155Name, erc1155Symbol);
      await this.erc1155.deployed();
      // console.log('erc1155 Token deployed at:', this.erc1155.address)
      this.market = await hre.ethers.getContractFactory('Market');
      this.market = await this.market.deploy();
      await this.market.deployed();
      // console.log('Market deployed at:', this.market.address)
      this.media = await hre.ethers.getContractFactory('Media');
      this.media = await this.media.deploy(
        this.erc1155.address,
        this.erc721.address,
        this.market.address,
      );
      await this.media.deployed();
      // console.log('media deployed at:', this.media.address)
      await this.market.configureMedia(this.media.address);
      // console.log('Configure Media address In market')
      await this.erc1155.configureMedia(this.media.address);
      await this.erc721.configureMedia(this.media.address);
      console.log('Media Added In ERC');
      await this.media.setAdminAddress(this.admin.address);
      // console.log('configured admin address')
      await this.media
        .connect(this.admin)
        .setCommissionPercentage(adminCommissionPercentage);
      console.log('configured Commission Percentage address');
    }
  });
  context('With ERC/LP token added to the field', function () {
    beforeEach(async function () {
      console.log(
        this.deployer.address,
        this.admin.address,
        this.alice.address,
        this.bob.address,
      );

      // * Math.pow(10, 18)
      const totalSupply = 10000000000;
      this.marhabaToken = await this.ERC20Mock.deploy(
        'Marhaba',
        'MRHB',
        convertToBigNumber(totalSupply),
      );
      this.mintParamsTuples = [
        mintObject.ipfsHash, // IPFS hash
        mintObject.title, // title
        mintObject.totalSupply, // totalSupply
        mintObject.royaltyPoints, // royaltyPoints
        mintObject.collabsAddresses, // collaborators
        mintObject.collabsPercentages, // percentages
        mintObject.auctionType, // askType  AUCTION - 0 , FIXED - 1
        mintObject.askAmount, // _askAmount
        mintObject.reserveAmount, // _reserveAmount
        this.marhabaToken.address, // currencyAsked
        mintObject.duration, // Auction End Time
      ];

      await this.marhabaToken.transfer(
        this.alice.address,
        convertToBigNumber(1000),
      );

      await this.marhabaToken.transfer(
        this.bob.address,
        convertToBigNumber(1000),
      );

      this.wrapperToken = await this.ERC20Mock.deploy(
        'Wrapper BNB',
        'WBNB',
        convertToBigNumber(totalSupply),
      );

      await this.wrapperToken.transfer(
        this.alice.address,
        convertToBigNumber(1000),
      );

      await this.wrapperToken.transfer(
        this.bob.address,
        convertToBigNumber(1000),
      );
    });

    it('It should Mint NFT for user', async function () {
      const tx = await mintTokens(
        this.media,
        this.alice,
        this.mintParamsTuples,
      );
      const tokenCounter = await fetchMintEvent(tx);
      expect(tokenCounter.toString()).to.equals('1');
    });
    it('Buy ERC721 NFT without collabs', async function () {
      const tx = await mintTokens(
        this.media,
        this.alice,
        this.mintParamsTuples,
      );
      const _tokenCounter = await fetchMintEvent(tx);
      expect(_tokenCounter.toString()).to.equals('1');

      // approve tokens before making request
      approveTokens(
        this.marhabaToken,
        this.bob,
        this.market.address,
        convertToBigNumber(1000),
      );
      // place bid
      await setBid(this.media, this.bob, _tokenCounter, [
        1, // quantity of the tokens being bid
        convertToBigNumber(5), // amount of ERC20 token being used to bid
        this.marhabaToken.address, // Address to the ERC20 token being used to bid,
        this.bob.address, // bidder address
        this.bob.address, // recipient address
        this.mintParamsTuples[6],

      ]);
      // fetch balances
      const balances = await getBalance(this.marhabaToken, [
        { name: 'alice', address: this.alice.address },
        { name: 'bob', address: this.bob.address },
        { name: 'collabs', address: this.mintParamsTuples[4][0] },
        { name: 'admin', address: this.admin.address },
      ]);
      expect(_tokenCounter.toString()).to.equals('1');
      expect(balances.alice).to.equals('1004.9');
      expect(balances.bob).to.equals('995.0');
      expect(balances.collabs).to.equals('0.0');
      expect(balances.admin).to.equals('0.1');
      expect(parseFloat(balances.alice) + parseFloat(balances.bob)).to.equals(
        1999.9,
      );
    });
    it('Buy ERC721 NFT with collabs', async function () {
      this.mintParamsTuples[4] = ['0x42eb768f2244c8811c63729a21a3569731535f06']; // collabs addresses
      this.mintParamsTuples[5] = [10]; // collabs percenrages
      this.mintParamsTuples[7] = convertToBigNumber(5); // ask Amount
      this.mintParamsTuples[8] = convertToBigNumber(5); // reserve Amount

      let mintTx = await this.media
        .connect(this.alice)
        .mintToken(this.mintParamsTuples);
      mintTx = await mintTx.wait(); // 0ms, as tx is already confirmed
      const event = mintTx.events.find(
        (event) => event.event === 'TokenCounter',
      );
      const [_tokenCounter] = event.args;
      expect(_tokenCounter.toString()).to.equals('1');

      // approve tokens before making request
      approveTokens(
        this.marhabaToken,
        this.bob,
        this.market.address,
        convertToBigNumber(1000),
      );

      // place bid
      await setBid(this.media, this.bob, _tokenCounter, [
        1, // quantity of the tokens being bid
        convertToBigNumber(5), // amount of ERC20 token being used to bid
        this.marhabaToken.address, // Address to the ERC20 token being used to bid,
        this.bob.address, // bidder address
        this.bob.address, // recipient address
        this.mintParamsTuples[6],

      ]);
      // fetch balances
      const balances = await getBalance(this.marhabaToken, [
        { name: 'alice', address: this.alice.address },
        { name: 'bob', address: this.bob.address },
        { name: 'collabs', address: this.mintParamsTuples[4][0] },
        { name: 'admin', address: this.admin.address },
      ]);

      expect(_tokenCounter.toString()).to.equals('1');
      expect(balances.alice).to.equals('1004.8755');
      expect(balances.bob).to.equals('995.0');
      expect(balances.collabs).to.equals('0.0245');
      expect(balances.admin).to.equals('0.1');
      expect(
        parseFloat(balances.alice) +
          parseFloat(balances.collabs) +
          parseFloat(balances.admin),
      ).to.equals(1005);
    });

    it('Buy 1155 NFT without collabs', async function () {
      this.mintParamsTuples[7] = convertToBigNumber(3); // ask Amount
      this.mintParamsTuples[8] = convertToBigNumber(3); // reserve Amount
      this.mintParamsTuples[2] = 5; // total supply
      this.mintParamsTuples[0] = 'generaterandom234234444';
      let mintTx = await this.media
        .connect(this.alice)
        .mintToken(this.mintParamsTuples);
      mintTx = await mintTx.wait(); // 0ms, as tx is already confirmed
      const event = mintTx.events.find(
        (event) => event.event === 'TokenCounter',
      );
      const [_tokenCounter] = event.args;
      expect(_tokenCounter.toString()).to.equals('1');

      // approve tokens before making request
      approveTokens(
        this.marhabaToken,
        this.bob,
        this.market.address,
        convertToBigNumber(1000),
      );
      // place bid
      await setBid(this.media, this.bob, _tokenCounter, [
        1, // quantity of the tokens being bid
        convertToBigNumber(3), // amount of ERC20 token being used to bid
        this.marhabaToken.address, // Address to the ERC20 token being used to bid,
        this.bob.address, // bidder address
        this.bob.address, // recipient address
        this.mintParamsTuples[6],
      ]);
      // fetch balances
      const balances = await getBalance(this.marhabaToken, [
        { name: 'alice', address: this.alice.address },
        { name: 'bob', address: this.bob.address },
        { name: 'collabs', address: this.mintParamsTuples[4][0] },
        { name: 'admin', address: this.admin.address },
      ]);

      expect(_tokenCounter.toString()).to.equals('1');
      expect(balances.alice).to.equals('1002.94');
      expect(balances.bob).to.equals('997.0');
      expect(balances.collabs).to.equals('0.0');
      expect(balances.admin).to.equals('0.06');
      expect(parseFloat(balances.alice) + parseFloat(balances.bob)).to.equals(
        1999.94,
      );
    });
    it('Should Fail Again Buy, Sold 1155 NFT without collabs', async function () {
      this.mintParamsTuples[7] = convertToBigNumber(3); // ask Amount
      this.mintParamsTuples[8] = convertToBigNumber(3); // reserve Amount
      this.mintParamsTuples[2] = 5; // total supply
      this.mintParamsTuples[0] = 'generaterandom234234444';
      let mintTx = await this.media
        .connect(this.alice)
        .mintToken(this.mintParamsTuples);
      mintTx = await mintTx.wait(); // 0ms, as tx is already confirmed
      const event = mintTx.events.find(
        (event) => event.event === 'TokenCounter',
      );
      const [_tokenCounter] = event.args;
      expect(_tokenCounter.toString()).to.equals('1');
      // approve tokens before making request
      approveTokens(
        this.marhabaToken,
        this.bob,
        this.market.address,
        convertToBigNumber(1000),
      );
      // place bid
      await setBid(this.media, this.bob, _tokenCounter, [
        2, // quantity of the tokens being bid
        convertToBigNumber(3), // amount of ERC20 token being used to bid
        this.marhabaToken.address, // Address to the ERC20 token being used to bid,
        this.bob.address, // bidder address
        this.bob.address, // recipient address
        this.mintParamsTuples[6],

      ]);
      // fetch balances
      const balances = await getBalance(this.marhabaToken, [
        { name: 'alice', address: this.alice.address },
        { name: 'bob', address: this.bob.address },
        { name: 'collabs', address: this.mintParamsTuples[4][0] },
        { name: 'admin', address: this.admin.address },
      ]);

      expect(_tokenCounter.toString()).to.equals('1');
      expect(balances.alice).to.equals('1002.94');
      expect(balances.bob).to.equals('997.0');
      expect(balances.collabs).to.equals('0.0');
      expect(balances.admin).to.equals('0.06');
      expect(parseFloat(balances.alice) + parseFloat(balances.bob)).to.equals(
        1999.94,
      );
      // Bought again request
      // place bid
      await expect(
        setBid(this.media, this.alice, _tokenCounter, [
          2, // quantity of the tokens being bid
          convertToBigNumber(3), // amount of ERC20 token being used to bid
          this.marhabaToken.address, // Address to the ERC20 token being used to bid,
          this.alice.address, // bidder address
          this.alice.address, // recipient address
          this.mintParamsTuples[6],
        ]),
      ).to.be.revertedWith('Token is not open for Sale');
    });
    it('Should Pass Again Buy, Sold 1155 NFT without collabs', async function () {
      this.mintParamsTuples[4] = ['0x5CB88D82E01C6C6FeB89fA5021706b449ad0b303'];
      this.mintParamsTuples[5] = [10];
      this.mintParamsTuples[7] = convertToBigNumber(3); // ask Amount
      this.mintParamsTuples[8] = convertToBigNumber(3); // reserve Amount
      this.mintParamsTuples[2] = 5; // total supply
      this.mintParamsTuples[0] = 'generaterandom234234444';
      let mintTx = await this.media
        .connect(this.alice)
        .mintToken(this.mintParamsTuples);
      mintTx = await mintTx.wait(); // 0ms, as tx is already confirmed
      const event = mintTx.events.find(
        (event) => event.event === 'TokenCounter',
      );
      const [_tokenCounter] = event.args;
      expect(_tokenCounter.toString()).to.equals('1');
      // approve tokens before making request
      approveTokens(
        this.marhabaToken,
        this.bob,
        this.market.address,
        convertToBigNumber(1000),
      );
      // place bid
      await setBid(this.media, this.bob, _tokenCounter, [
        this.mintParamsTuples[2], // quantity of the tokens being bid
        convertToBigNumber(3), // amount of ERC20 token being used to bid
        this.marhabaToken.address, // Address to the ERC20 token being used to bid,
        this.bob.address, // bidder address
        this.bob.address, // recipient address
        this.mintParamsTuples[6],
      ]);
      // fetch balances
      let balances = await getBalance(this.marhabaToken, [
        { name: 'alice', address: this.alice.address },
        { name: 'bob', address: this.bob.address },
        { name: 'collabs', address: this.mintParamsTuples[4][0] },
        { name: 'admin', address: this.admin.address },
      ]);

      expect(_tokenCounter.toString()).to.equals('1');
      expect(balances.alice).to.equals('1002.9253');
      expect(balances.bob).to.equals('997.0');
      expect(balances.collabs).to.equals('0.0147');
      expect(balances.admin).to.equals('0.06');
      expect(parseFloat(balances.alice) + parseFloat(balances.bob)).to.equals(
        1999.9252999999999,
      );
      // Bought again request

      // approve tokens before making request
      approveTokens(
        this.marhabaToken,
        this.alice,
        this.market.address,
        convertToBigNumber(1000),
      );
      this.mintParamsTuples[7] = convertToBigNumber(100); // ask Amount
      this.mintParamsTuples[8] = convertToBigNumber(100); // reserve Amount

      console.log('ask placed in pass buy');
      await this.media
        .connect(this.bob)
        .setAsk(
          _tokenCounter,
          [
            this.bob.address,
            this.mintParamsTuples[7],
            this.mintParamsTuples[8],
            this.mintParamsTuples[2],
            this.marhabaToken.address,
            this.mintParamsTuples[6],
            0,
            0,
            this.mintParamsTuples[4][0],
            0,
          ],
          {
            from: this.bob.address,
          },
        );

      await setBid(this.media, this.alice, _tokenCounter, [
        this.mintParamsTuples[2], // quantity of the tokens being bid
        convertToBigNumber(100), // amount of ERC20 token being used to bid
        this.marhabaToken.address, // Address to the ERC20 token being used to bid,
        this.alice.address, // bidder address
        this.alice.address, // recipient address
        this.mintParamsTuples[6],
      ]);
      balances = await getBalance(this.marhabaToken, [
        { name: 'alice', address: this.alice.address },
        { name: 'bob', address: this.bob.address },
        { name: 'collabs', address: this.mintParamsTuples[4][0] },
        { name: 'admin', address: this.admin.address },
      ]);

      expect(balances.alice).to.equals('907.8253');
      expect(balances.bob).to.equals('1090.1');
      expect(balances.collabs).to.equals('0.0147');
      expect(balances.admin).to.equals('2.06');
      expect(
        parseFloat(balances.alice) +
          parseFloat(balances.bob) +
          parseFloat(balances.admin),
      ).to.equals(1999.9852999999998);
    });
  });
});
