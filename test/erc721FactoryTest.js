// test/ERC721-test.js
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const parseEther = ethers.utils.parseEther;


describe("ERCFactory contracts", function () {
    let ERC721Factory, ERC2981;
    let token721, erc2981;

    let account1, account2, account3, account4, account5;

    let name='Artwork Contract';
    let symbol='ART';
    let defaultRoyalty = true;
    let defaultRoyaltyReceiver = ["0xb64a30399f7F6b0C154c2E7Af0a3ec7B0A5b131a"];
    let royaltyFeesInBips = [1000];
	const ADDRESS_ZERO = ethers.constants.AddressZero;

    beforeEach(async function () {
        [owner, account1, account2, account3, account4, account5] = await ethers.getSigners();
        // console.log("owner: ", owner.address);

        ERC721Factory = await ethers.getContractFactory("ERC721Factory")
        ERC2981 = await ethers.getContractFactory("ERC2981")

        token721 = await ERC721Factory.connect(owner).deploy(
            name,
            symbol,
            defaultRoyalty,
            defaultRoyaltyReceiver, 
            royaltyFeesInBips);

        erc2981 = await ERC2981.connect(owner).deploy();
        // console.log("token721 is deployed to :", token721.address)
    });

    // You can nest describe calls to create subsections.
    describe("Deployment", function () {
        it("Should have the correct name and symbol ", async function () {
            expect(await token721.name()).to.equal(name);
            expect(await token721.symbol()).to.equal(symbol);
        });
    });

    describe('ERC721Factory Minting', async function () {
        it('mint an 721Factory token without royalty', async () => {
            // alice mint a token
            expect(await 
                token721.safeMint(
                    owner.address,
                    false,
                    [],
                    []
                )
            )
            // check owner
            const ownerOfToken0 = await token721.ownerOf(0);
            expect(ownerOfToken0).to.equals(owner.address)  
        })

        it('mint an 721Factory token with more than 5 royalty receivers', async () => {
            await expect(
                token721.safeMint(
                    owner.address,
                    true,
                    [
                        owner.address, 
                        account1.address, 
                        account2.address, 
                        account3.address, 
                        account4.address,
                        account5.address, 
                    ],
                    [
                        "250", 
                        "500",
                        "250",
                        "250",
                        "500",
                        "250",
                    ]
                )
            ).to.be.revertedWith("Too many royalty recievers details")
        })

        it('mint an 721Factory token with mismatch of royalty and receivers', async () => {
            await expect(
                token721.safeMint(
                    owner.address,
                    true,
                    [
                        owner.address, 
                        account1.address, 
                        account2.address, 
                        account3.address, 
                        account4.address,
                    ],
                    [
                        "250", 
                        "500",
                        "250",
                        "250",
                    ]
                )
            ).to.be.revertedWith("Mismatch of Royalty recievers and their fees")
        })
    })

    describe('ERC721Factory Minting with Whitelisting', async () => {
        it('ERC 721 Minting cannot be done when whitelist is enabled and the address is not whitelisted', async () => {
            await token721.setWhitelistEnabled(true);
            await token721.setWhitelist([account2.address, account3.address]);
            const tx =  token721.connect(account1).safeMint(
                    account1.address,
                    false,
                    [],
                    []
                )
            await expect(tx).to.be.revertedWith('Address not whitelisted')
        })
        it('ERC 721 Minting can be done when whitelist is enabled and the address is whitelisted', async () => {
            await token721.setWhitelistEnabled(true);
            await token721.setWhitelist([account2.address, account3.address]);
            expect(await 
                token721.connect(account2).safeMint(
                    account2.address,
                    false,
                    [],
                    []
                )
            )
            // check owner
            const ownerOfToken0 = await token721.ownerOf(0);
            expect(ownerOfToken0).to.equals(account2.address)
        })
    })

    describe('ERC721Factory Transfer', async () => {
        it('ERC 721Factory Transfer token between accounts', async () => {
            expect(await 
                token721.connect(owner).safeMint(
                    owner.address,
                    false,
                    [],
                    []
                )
            )
            const ownerOfToken0 = await token721.ownerOf(0);
            expect(ownerOfToken0).to.equals(owner.address)
            await token721.connect(owner).transferFrom(owner.address, account3.address, 0);
            const newOwnerOfToken0 = await token721.ownerOf(0);
            expect(newOwnerOfToken0).to.equals(account3.address)
        })
    })
  
    // describe('ERC721Factory Burn', async function () {
    //     it('ERC721Factory Burn', async () => {
    //         expect(await 
    //             token721.connect(owner).safeMint(
    //                 owner.address,
    //                 false,
    //                 [],
    //                 []
    //             )
    //         )
    //     })
    // });
  
});
