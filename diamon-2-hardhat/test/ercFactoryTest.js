// test/ERC721-test.js
const { expect } = require("chai");

describe("ERCFactory contracts", function () {
    let ERC721Factory, ERC1155Factory, ERC721AFactory, ERC721RFactory;
    let token721, token1155, token721A, token721R;

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

    beforeEach(async function () {
    ERC721Factory = await ethers.getContractFactory("ERC721Factory")
    ERC1155Factory = await ethers.getContractFactory("ERC1155Factory")
    ERC721AFactory = await ethers.getContractFactory("ERC721AFactory")
    ERC721RFactory = await ethers.getContractFactory("ERC721RFactory")

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
    });

    // You can nest describe calls to create subsections.
    describe("Deployment", function () {
        it("Should have the correct name and symbol ", async function () {
            expect(await token721.name()).to.equal(name);
            expect(await token721.symbol()).to.equal(symbol);
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

        it('mint an erc1155 token with royalty', async () => {
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

