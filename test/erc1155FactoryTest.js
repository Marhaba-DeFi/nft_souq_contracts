// test/ERC1155-test.js
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const parseEther = ethers.utils.parseEther;


describe("ERCFactory contracts", function () {
    let ERC1155Factory, ERC2981;
    let token1155, erc2981;

    let account1, account2, account3, account4, account5;

    let name='Artwork Contract';
    let symbol='ART';
    let copies = 10;
    let defaultRoyalty = true;
    let defaultRoyaltyReceiver = ["0xb64a30399f7F6b0C154c2E7Af0a3ec7B0A5b131a"];
    let royaltyFeesInBips = [1000];
	const ADDRESS_ZERO = ethers.constants.AddressZero;

    beforeEach(async function () {
        [owner, account1, account2, account3, account4, account5] = await ethers.getSigners();
        // console.log("owner: ", owner.address);

        ERC1155Factory = await ethers.getContractFactory("ERC1155Factory")
        ERC2981 = await ethers.getContractFactory("ERC2981")

        token1155 = await ERC1155Factory.connect(owner).deploy(
            name,
            symbol,
            defaultRoyalty,
            defaultRoyaltyReceiver, 
            royaltyFeesInBips);

        erc2981 = await ERC2981.connect(owner).deploy();
        // console.log("token1155 is deployed to :", token1155.address)
    });

    // You can nest describe calls to create subsections.
    describe("Deployment", function () {
        it("Should have the correct name and symbol ", async function () {
            expect(await token1155.name()).to.equal(name);
            expect(await token1155.symbol()).to.equal(symbol);
        });
    });

    describe('ERC1155Factory Minting', async function () {
        it('mint an 1155Factory token without royalty', async () => {
            // alice mint a token
            expect(await 
                token1155.mint(
                    owner.address,
                    copies,
                    false,
                    [],
                    []
                )
            ).to.emit(token1155, "Transfer")
			.withArgs(ethers.constants.AddressZero, owner.address, 0)
            // check owner
            const ownerOfToken0 = await token1155.balanceOf(owner.address, 0);
            expect(ownerOfToken0).to.equals(10)  
        })

		it('mint an ERC1155Factory token with royalty', async () => {
            // alice mint a token
            expect(await 
                token1155.mint(
                    owner.address,
                    copies,
                    true,
                    [owner.address, account1.address],
                    [1000,2000]
                )
            )
            // check owner
            const ownerOfToken0 = await token1155.balanceOf(owner.address, 0);
            expect(ownerOfToken0).to.equals(10)  
			const royaltyInfo = await token1155.royaltyInfo(0, 5000);
			expect(royaltyInfo[0][0]).to.be.equal(owner.address);
			expect(royaltyInfo[0][1]).to.be.equal(account1.address);
			expect(Number(royaltyInfo[1][0])).to.be.equal(BigNumber.from(500));
			expect(Number(royaltyInfo[1][1])).to.be.equal(BigNumber.from(1000));
        })

        it('mint an 1155Factory token with more than 5 royalty receivers', async () => {
            await expect(
                token1155.mint(
                    owner.address,
                    copies,
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

        it('mint an 1155Factory token with mismatch of royalty and receivers', async () => {
            await expect(
                token1155.mint(
                    owner.address,
                    copies,
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

    describe('ERC1155Factory Minting with Whitelisting', async () => {
        it('ERC 1155 Minting cannot be done when whitelist is enabled and the address is not whitelisted', async () => {
            await token1155.setWhitelistEnabled(true);
            await token1155.setWhitelist([account2.address, account3.address]);
            const tx =  token1155.connect(account1).mint(
                    account1.address,
                    copies,
                    false,
                    [],
                    []
                )
            await expect(tx).to.be.revertedWith('Address not whitelisted')
        })
        it('ERC 1155 Minting can be done when whitelist is enabled and the address is whitelisted', async () => {
            await token1155.setWhitelistEnabled(true);
            await token1155.setWhitelist([account2.address, account3.address]);
            expect(await 
                token1155.connect(account2).mint(
                    account2.address,
                    copies,
                    false,
                    [],
                    []
                )
            )
            // check owner
            const ownerOfToken0 = await token1155.balanceOf(account2.address, 0);
            expect(ownerOfToken0).to.equals(10)  
        })
    })

    describe('ERC1155Factory Transfer', async () => {
        it('ERC 1155Factory Transfer token between accounts', async () => {
            expect(await 
                token1155.connect(owner).mint(
                    owner.address,
                    copies,
                    false,
                    [],
                    []
                )
            )
            const ownerOfToken0 = await token1155.balanceOf(owner.address, 0);
            expect(ownerOfToken0).to.equals(10)  
            await token1155.connect(owner).transfer(owner.address, account3.address, 0, 5);
            const newOwnerOfToken0 = await token1155.balanceOf(account3.address, 0);
            expect(newOwnerOfToken0).to.equals(5)  
        })
    })
  
    describe('ERC1155Factory Burn', async function () {
        it('ERC1155Factory Burn', async () => {
            await token1155.connect(owner).mint(
                    owner.address,
                    copies,
                    false,
                    [],
                    []
                )
            expect(await token1155.connect(owner).burn(owner.address, 0, 2))
			.emit(token1155, "TransferSingle").withArgs(owner, owner, ethers.constants.AddressZero, 0, 2);;
            const ownerOfToken0 = await token1155.balanceOf(owner.address, 0);
            expect(ownerOfToken0).to.equals(8)  
        })
    });
  
});
