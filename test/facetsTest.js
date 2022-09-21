const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')

const { assert, expect } = require('chai')
const { ethers } = require('hardhat')

describe('FacetsTest', async function () {

  beforeEach(async () => {
    let { 
      souqNFTDiamond,
      erc721FactoryFacet,
      erc1155FactoryFacet,
      marketFacet,
      mediaFacet,
      signer,
      alice,
      bob,
      carol,
      dave,
      frank,
     } = await deployDiamond({ withFacets: true })

    // deploy MRHB token
    const MRHBToken = await hre.ethers.getContractFactory(
    'ERC20Mock',
    );
    global.MRHBToken = await MRHBToken.deploy("MARHABA", "MRHB", 1_000_000);
    await global.MRHBToken.deployed();

    // transfer MRHB token for participants
    let participants = [alice, bob, carol, dave, frank];

    for (let i = 0; i < participants.length; i++) {
      global.MRHBToken.transfer(participants[i].address, ethers.utils.formatUnits("100"))
    }

    global.souqNFTDiamond = souqNFTDiamond
    global.erc721FactoryFacet = erc721FactoryFacet
    global.erc1155FactoryFacet = erc1155FactoryFacet
    global.marketFacet = marketFacet
    global.mediaFacet = mediaFacet
    global.signer = signer
    global.alice = alice
    global.bob = bob
    global.carol = carol
    global.dave = dave
    global.frank = frank
  })

  describe('Configurations', async function () {

    it('configure admin commission', async () => {
        // set admin commission percentage
        await global.mediaFacet.setCommissionPercentageMedia(250)
        
        // get admin commission percentage
        const commissionPercentage = await global.mediaFacet.getAdminCommissionPercentageMedia()
        
        expect(commissionPercentage).to.equal(250)
    })

    it('configure new token', async () => {
        // add MRHB token to the souq NFT
        await global.mediaFacet.setApprovedCryptoMedia(global.MRHBToken.address, true)
        
        // check if MRHB token is approved in souq NFT
        const isApproved = await global.mediaFacet.getApprovedCryptoMedia(global.MRHBToken.address)
        
        expect(isApproved).to.equal(true)
    })

    it('disable a token', async () => {
        // disable  the MRHB token in souq NFT
        await global.mediaFacet.setApprovedCryptoMedia(global.MRHBToken.address, false)
        
        // check if MRHB token is approved in souq NFT
        const isApproved = await global.mediaFacet.getApprovedCryptoMedia(global.MRHBToken.address)
        
        expect(isApproved).to.equal(false)
    })

  })

  describe('Minting', async function () {
    it('mint an erc721 token without collabs', async () => {
      // check if token with id 0 exist
      let isToken0Exist = await global.mediaFacet.istokenIdExistMedia(
        0,
        "ERC721"
      )
      await expect(isToken0Exist).to.equals(false)
      
      // alice mint a token
     await expect(
          global.mediaFacet.mintTokenMedia(
          global.alice.address,
          0,
          'ERC721',
          1,
          "tokenUri",
          false,
          [],
          []
        )
      ).to.emit(global.erc721FactoryFacet, "Transfer").withArgs(ethers.constants.AddressZero, global.alice.address, 0)

      // check if token with id 0 exist
      isToken0Exist = await global.mediaFacet.istokenIdExistMedia(
        0,
        "ERC721"
      )
      
      await expect(isToken0Exist).to.equals(true)
      
      // check owner
      const ownerOfToken0 = await global.erc721FactoryFacet.ownerOf(0);
      
      expect(ownerOfToken0).to.equals(global.alice.address)

      // check collaborators
      const token0Collaborators = await global.mediaFacet.getCollaboratorsMedia(global.souqNFTDiamond.address,  0);

      expect(token0Collaborators.collaborators.length).to.equals(0)
      expect(token0Collaborators.collabFraction.length).to.equals(0)
      
      // check royalties
      const token0RoyaltyInfo = await global.erc721FactoryFacet.royaltyInfo721(0, ethers.utils.parseUnits("10"));
      
      expect(token0RoyaltyInfo[0].length).to.equals(0)
      expect(token0RoyaltyInfo[1].length).to.equals(0)
      
    })

    it('mint an erc721 token with collabs', async () => {
      // check if token with id 1 exist
      const isToken1Exist = await global.mediaFacet.istokenIdExistMedia(
        0,
        "ERC721"
      )
      await expect(isToken1Exist).to.equals(false)
      
      // alice mint a token
     await expect(
          global.mediaFacet.mintTokenMedia(
          global.alice.address,
          0,
          'ERC721',
          1,
          "tokenUri",
          false,
          [],
          []
        )
      ).to.emit(global.erc721FactoryFacet, "Transfer").withArgs(ethers.constants.AddressZero, global.alice.address, 0)

      // alice add collabs
      const collaborators = [global.alice.address, global.bob.address]
      const collabFractions = ["250", "500"]

      await expect(
        global.mediaFacet.connect(global.alice).setCollaboratorsMedia(
          global.souqNFTDiamond.address, 
          0, 
          collaborators,  
          collabFractions
        )
      ).to.emit(global.marketFacet, "CollaboratorsFee")
      .withArgs(
        global.souqNFTDiamond.address,
        0,
        collaborators,
        collabFractions
      )

      // check owner
      const ownerOfToken0 = await global.erc721FactoryFacet.ownerOf(0);
        
      expect(ownerOfToken0).to.equals(global.alice.address)

      // check collaborators
      const token0Collaborators = await global.mediaFacet.getCollaboratorsMedia(global.souqNFTDiamond.address,  0);

      expect(token0Collaborators.collaborators.length).to.equals(2)
      expect(token0Collaborators.collabFraction.length).to.equals(2)
      
      // check royalties
      const token0RoyaltyInfo = await global.erc721FactoryFacet.royaltyInfo721(0, ethers.utils.parseUnits("10"));
      
      expect(token0RoyaltyInfo[0].length).to.equals(0)
      expect(token0RoyaltyInfo[1].length).to.equals(0)
    })

    it('mint an erc721 token with more than 5 collabs', async () => {
        await global.mediaFacet.mintTokenMedia(
        global.alice.address,
        0,
        'ERC721',
        1,
        "tokenUri",
        false,
        [],
        []
      )

      // alice add collabs
      const collaborators = [
        global.alice.address, 
        global.bob.address, 
        global.carol.address, 
        global.dave.address, 
        global.frank.address,
        global.alice.address, 
      ]
      const collabFractions = [
        "250", 
        "500",
        "250",
        "250",
        "500",
        "250",
      ]

      await expect(
        global.mediaFacet.connect(global.alice).setCollaboratorsMedia(
          global.souqNFTDiamond.address, 
          0, 
          collaborators,  
          collabFractions
        )
      ).to.be.revertedWith("Too many Collaborators")
    })

    it('mint an erc721 token with mismatch of collaborators and fractions', async () => {
        await global.mediaFacet.mintTokenMedia(
        global.alice.address,
        0,
        'ERC721',
        1,
        "tokenUri",
        false,
        [],
        []
      )

      // alice add collabs
      const collaborators = [
        global.alice.address, 
        global.bob.address, 
        global.carol.address, 
        global.dave.address, 
        global.frank.address,
      ]
      const collabFractions = [
        "250", 
        "500",
        "250",
        "250",
      ]

      await expect(
        global.mediaFacet.connect(global.alice).setCollaboratorsMedia(
          global.souqNFTDiamond.address, 
          0, 
          collaborators,  
          collabFractions
        )
      ).to.be.revertedWith("Mismatch of Collaborators and their share")
    })
    
    it('mint an erc1155 token', async () => {
      // check if token with id 0 exist
      const isToken0Exist = await global.mediaFacet.istokenIdExistMedia(
        0,
        "ERC115"
      )
      await expect(isToken0Exist).to.equals(false)
      
      // alice mint a token
      await expect(
            global.mediaFacet.mintTokenMedia(
            global.alice.address,
            0,
            'ERC1155',
            10,
            "tokenUri",
            false,
            [],
            []
          )
        ).to.emit(global.erc1155FactoryFacet, "TransferSingle")
        .withArgs(
          global.souqNFTDiamond.address,
          ethers.constants.AddressZero,
          global.alice.address,
          0,
          10
        )
      
      // check owner balance
      const ownerBalanceOfToken0 = await global.erc1155FactoryFacet.balanceOf(global.alice.address, 0);
      
      expect(ownerBalanceOfToken0).to.equals(10)
      
    })
  })

  describe('Burning', async function () {
    it ("burn an erc721 token without collabs", async () => {
      // alice mint a token
      await global.mediaFacet.mintTokenMedia(
        global.alice.address,
        0,
        'ERC721',
        1,
        "tokenUri",
        false,
        [],
        []
      )

      // alice burn the token
      await expect(
        global.mediaFacet.burnTokenMedia(
          0,
          "ERC721",
          1
        )
      ).emit(global.erc721FactoryFacet, "Approval")
      .withArgs(global.alice.address, ethers.constants.AddressZero, 0)
      .emit(global.erc721FactoryFacet, "Transfer")
      .withArgs(global.alice.address, ethers.constants.AddressZero, 0)

      // check if token with id 0 exist
      const isToken0Exist = await global.mediaFacet.istokenIdExistMedia(
        0,
        "ERC721"
      )
      
      await expect(isToken0Exist).to.equals(false)
    })

    it ("burn an erc721 token with collabs", async () => {
      // alice mint a token
      await global.mediaFacet.mintTokenMedia(
        global.alice.address,
        0,
        'ERC721',
        1,
        "tokenUri",
        false,
        [],
        []
      )

      // alice add collabs
      const collaborators = [global.alice.address, global.bob.address]
      const collabFractions = ["250", "500"]

      await expect(
        global.mediaFacet.connect(global.alice).setCollaboratorsMedia(
          global.souqNFTDiamond.address, 
          0, 
          collaborators,  
          collabFractions
        )
      ).to.emit(global.marketFacet, "CollaboratorsFee")
      .withArgs(
        global.souqNFTDiamond.address,
        0,
        collaborators,
        collabFractions
      )

      // alice burn the token
      await expect(
        global.mediaFacet.burnTokenMedia(
          0,
          "ERC721",
          1
        )
      ).emit(global.erc721FactoryFacet, "Approval")
      .withArgs(global.alice.address, ethers.constants.AddressZero, 0)
      .emit(global.erc721FactoryFacet, "Transfer")
      .withArgs(global.alice.address, ethers.constants.AddressZero, 0)

      // check if token with id 0 exist
      const isToken0Exist = await global.mediaFacet.istokenIdExistMedia(
        0,
        "ERC721"
      )
      
      await expect(isToken0Exist).to.equals(false)

      // check collaborators
      // return 2 should be 0 as token has burned
      // const token0Collaborators = await global.mediaFacet.getCollaboratorsMedia(global.souqNFTDiamond.address,  0);
      // expect(token0Collaborators.collaborators.length).to.equals(0)
      // expect(token0Collaborators.collabFraction.length).to.equals(0)
    })

    it('burn an erc1155 token', async () => {
      // alice mint a token
      await global.mediaFacet.mintTokenMedia(
      global.alice.address,
      0,
      'ERC1155',
      10,
      "tokenUri",
      false,
      [],
      []
    )
        
    await expect(
      global.mediaFacet.connect(global.alice).burnTokenMedia(
        0,
        "ERC1155",
        10
      )
    ).emit(global.erc1155FactoryFacet, "TransferSingle")
    .withArgs(
      global.souqNFTDiamond.address,
      global.alice.address,
      ethers.constants.AddressZero,
      0,
      10
    )

    // check if token with id 0 exist
    const aliceBalanceOfToken0 = await global.erc1155FactoryFacet.balanceOf(
      global.alice.address,
      0
    )
    
    expect(aliceBalanceOfToken0).to.equals(0)
      
    })

    describe.skip('Bidding', async function () {
      it('bid on erc721 token', async () => {
          // alice mint a token
          global.mediaFacet.mintTokenMedia(
          global.alice.address,
          0,
          'ERC721',
          1,
          "tokenUri",
          false,
          [],
          []
        )

        // accept a bid
        await expect(
          global.mediaFacet.acceptBidMedia(
            "ERC721",
            global.souqNFTDiamond.address,
            global.MRHBToken.address,
            global.alice.address,
            global.bob.address,
            0,
            ethers.utils.parseUnits("10"),
            1,
            // bytes memory _bidderSig,
            // bytes memory _sellerSig
        )
        ).emit(global.erc721FactoryFacet, "BidAccepted")
        .withArgs(global.alice.address, global.bob.address, true)
        .to.changeTokenBalances(
          global.MRHBToken, 
          [global.alice.address, global.bob.address], 
          [10, -10], 
          { includeFee: true }
        )
      })

      it('bid on erc1155 token', async () => {
          // alice mint a token
          global.mediaFacet.mintTokenMedia(
          global.alice.address,
          0,
          'ERC1155',
          10,
          "tokenUri",
          false,
          [],
          []
        )

        // accept a bid
        await expect(
          global.mediaFacet.acceptBidMedia(
            "ERC1155",
            global.souqNFTDiamond.address,
            global.MRHBToken.address,
            global.alice.address,
            global.bob.address,
            0,
            ethers.utils.parseUnits("10"),
            10,
            // bytes memory _bidderSig,
            // bytes memory _sellerSig
        )
        ).emit(global.erc721FactoryFacet, "BidAccepted").withArgs(global.alice.address, global.bob.address, true)
        .to.changeTokenBalances(
          global.MRHBToken, 
          [global.alice.address, global.bob.address], 
          [10, -10], 
          { includeFee: true }
        )
      })
    })


  })
})
