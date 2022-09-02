// test/ERC721-test.js
const { expect } = require("chai");

describe("ERCFactory contracts", function () {
    let ERC721Factory, ERC1155Factory, ERC721AFactory, ERC721RFactory, ERC2981;
    let token721, token1155, token721A, token721R, erc2981;

    let name='Artwork Contract';
    let symbol='ART';
    let copies = 10;
    let defaultRoyalty = false;
    let royaltyReceiver = ["0xaB856c0f5901432DEb88940C9423c555814BC0fd"];
    let royaltyFeesInBips = [0000];
    let mintSupply = 1000;
    let mintingPrice = 1000;
    let refundTime = 86400 // 1 day in sec;
    let maxMintPerUser = 5;
    let alice="0x71593BAc0b4aE5278f784f0910f4829A103Ba7Cd";
    let bob= "0x032779f45b50d0Fa6F55692C18548DfC6ca1E58F";
    let dave="0x5c381DF64b818E54E2ff78FeD0036Ea9a984B028";
    let carol="0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
    let frank="0xCcd5FAA0C14641319f31eD72158d35BE6b9b90Da";
    let jane="0xAEB8Fa0Bf852f412CaE5897Cf2E24E7E9aC60944";

    beforeEach(async function () {
        ERC721Factory = await ethers.getContractFactory("ERC721Factory")
        ERC1155Factory = await ethers.getContractFactory("ERC1155Factory")
        ERC721AFactory = await ethers.getContractFactory("ERC721AFactory")
        ERC721RFactory = await ethers.getContractFactory("ERC721RFactory")
        ERC2981 = await ethers.getContractFactory("ERC2981")

        token721 = await ERC721Factory.deploy(
            name,
            symbol,
            defaultRoyalty,
            royaltyReceiver, 
            royaltyFeesInBips);

        token1155 = await ERC1155Factory.deploy(
            name,
            symbol,
            defaultRoyalty,
            royaltyReceiver, 
            royaltyFeesInBips);

        token721A = await ERC721AFactory.deploy(
            name,
            symbol);

        token721R = await ERC721RFactory.deploy(
            name,
            symbol,
            mintSupply,
            mintingPrice,
            refundTime,
            maxMintPerUser);

        erc2981 = await ERC2981.deploy();
        
    });

    // You can nest describe calls to create subsections.
    describe("Deployment", function () {
        it("Should have the correct name and symbol ", async function () {
            expect(await token721.name()).to.equal(name);
            expect(await token721.symbol()).to.equal(symbol);
            expect(await token721R.name()).to.equal(name);
            expect(await token721R.symbol()).to.equal(symbol);
        });
    });

    describe('Minting Factory token', async function () {
        it('mint an erc721 token without royalty', async () => {
            // alice mint a token
            await expect(
                token721.safeMint(
                    alice,
                    false,
                    [],
                    []
                )
            )
            // check owner
            const ownerOfToken0 = await token721.ownerOf(0);
            expect(ownerOfToken0).to.equals(alice)  
        })

        it('mint an erc721 token with more than 5 royalty receivers', async () => {
            await expect(
                token721.safeMint(
                    alice,
                    true,
                    [
                        alice, 
                        bob, 
                        carol, 
                        dave, 
                        frank,
                        jane, 
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

        it('mint an erc1155 token without royalty', async () => {
            // alice mint a token
            await expect(
                token1155.mint(
                    alice,
                    copies,
                    false,
                    [],
                    []
                )
            )
            // check balance of owner
            const ownerOfToken0 = await token1155.balanceOf(alice, 0);
            expect(ownerOfToken0).to.equals(10) 
        })

        it('mint an erc1155 token with mismatch of royalty and receivers', async () => {
            await expect(
                token1155.mint(
                    alice,
                    copies,
                    true,
                    [
                        alice, 
                        bob, 
                        carol, 
                        dave, 
                        frank,
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

        it('mint 10 erc721A tokens', async () => {
          
            // alice mint a token
            await expect(
            token721A.mint(
                    10,
                    alice
                )
            )
            // check owner
            const ownerOfToken0 = await token721A.ownerOf(0);
            expect(ownerOfToken0).to.equals(alice)  
            const ownerOfToken9 = await token721A.ownerOf(9);
            expect(ownerOfToken9).to.equals(alice)
        })
    })
});


