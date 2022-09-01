// test/ERC721-test.js
const { expect } = require("chai");

describe("ERC721Factory contract", function () {
    let ERC721Factory;
    let token721;
    let _name='Artwork Contract';
    let _symbol='ART';
    let defaultRoyalty = false;
    let royaltyReceiver = ["0xaB856c0f5901432DEb88940C9423c555814BC0fd"];
    let royaltyFeesInBips = [0000];
    let account1,otheraccounts;

    beforeEach(async function () {
    ERC721Factory = await ethers.getContractFactory("ERC721Factory")
    //    [owner, account1, ...otheraccounts] = await ethers.getSigners();

        token721 = await ERC721Factory.deploy(_name,_symbol,defaultRoyalty,royaltyReceiver, royaltyFeesInBips);
    });

    // You can nest describe calls to create subsections.
    describe("Deployment", function () {

        it("Should has the correct name and symbol ", async function () {
        expect(await token721.name()).to.equal(_name);
        expect(await token721.symbol()).to.equal(_symbol);
        });
    });
});