// test/ERC721A-test.js
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
// const parseEther = ethers.utils.parseEther;
const _INTERFACE_ID_ERC165 = '0x01ffc9a7';
const _INTERFACE_ID_ROYALTIES_EIP2981 = '0x2a55205a';
const _INTERFACE_ID_ERC721A = '0x80ac58cd';


describe("ERC721AFactory contracts", function () {
    let ERC721AFactory, ERC2981;
    let token721A, erc2981;

    let account1, account2, account3;

    let name='Artwork Contract';
    let symbol='ART';
	const ADDRESS_ZERO = ethers.constants.AddressZero;

    beforeEach(async function () {
        [owner, account1, account2, account3] = await ethers.getSigners();

        ERC721AFactory = await ethers.getContractFactory("ERC721AFactory")
        ERC2981 = await ethers.getContractFactory("ERC2981")

        token721A = await ERC721AFactory.connect(owner).deploy(
            name,
            symbol);
    });

    // You can nest describe calls to create subsections.
    describe("Deployment", function () {
        it("Should have the correct name and symbol ", async function () {
            expect(await token721A.name()).to.equal(name);
            expect(await token721A.symbol()).to.equal(symbol);
        });
    });

    describe('ERC721AFactory Minting', async function () {
        it('mint an 721AFactory token', async () => {
            it('mint erc721A tokens', async () => {
                expect(await
                token721A.mint(
                        10,
                        account1.address
                    )
                ).to.emit(token721A, "Transfer")
				.withArgs(ethers.constants.AddressZero, account1.address, 10)
                expect(await
                    token721A.mint(
                    10,
                    account2.address)
                ).to.emit(token721A, "Transfer")
				.withArgs(ethers.constants.AddressZero, account2.address, 20)
                // check owner
                const ownerOfToken0 = await token721A.ownerOf(0);
                expect(ownerOfToken0).to.equals(account1.address)  
                const ownerOfToken9 = await token721A.ownerOf(9);
                expect(ownerOfToken9).to.equals(account1.address)
                const balance = await token721A.balanceOf(account1.address);
                expect(balance).to.equals(10)
                const ownerOfToken10 = await token721A.ownerOf(10);
                expect(ownerOfToken10).to.equals(account2.address)
            })
        })
    })

    describe('ERC721AFactory Minting with Whitelisting', async () => {
        it('ERC 721A Minting cannot be done when whitelist is enabled and the address is not whitelisted', async () => {
            await token721A.setWhitelistEnabled(true);
            await token721A.setWhitelist([account2.address, account3.address]);
            const tx =  token721A.connect(account1).mint(
                10,
                account1.address
            )
            await expect(tx).to.be.revertedWith('Address not whitelisted')
        })
        it('ERC 721A Minting can be done when whitelist is enabled and the address is whitelisted', async () => {
            await token721A.setWhitelistEnabled(true);
            await token721A.setWhitelist([account2.address, account3.address]);
            expect(await 
                token721A.connect(account2).mint(
                    10,
                    account2.address
                )
            )
            // check owner
            const ownerOfToken0 = await token721A.ownerOf(0);
            expect(ownerOfToken0).to.equals(account2.address)
        })
    })

    describe('ERC721A Transfer', async () => {
        it('ERC 721A Transfer token between accounts', async () => {
            // alice mint a token
            await token721A.setWhitelistEnabled(true);
            await token721A.setWhitelist([account2.address, account3.address]);
            expect(await token721A.connect(account2).mint(
                    10,
                    account2.address
                )
            )
            expect(await token721A.connect(account3).mint(
                10,
                account3.address
                )
            )
            // check owner
            const ownerOfToken0 = await token721A.ownerOf(0);
            expect(ownerOfToken0).to.equals(account2.address) 
            const balance = await token721A.balanceOf(account2.address);
            expect(balance).to.equals(10)
            const ownerOfToken10 = await token721A.ownerOf(10);
            expect(ownerOfToken10).to.equals(account3.address);
    
            await token721A.connect(account2).transferFrom(account2.address, account3.address, 5);
            const addr2Balance = await token721A.balanceOf(account3.address);
            expect(addr2Balance).to.equal(11);
        })
    })
  
    describe('burn', async function () {
        it('ERC 721A Burn', async () => {
            await token721A.setWhitelistEnabled(true);
            await token721A.setWhitelist([account2.address]);
            expect(await
            token721A.connect(account2).mint(
                    10,
                    account2.address
                )
            )
            // check owner
            const ownerOfToken0 = await token721A.ownerOf(0);
            expect(ownerOfToken0).to.equals(account2.address)  
            await token721A.connect(account2).burn(5);
            // const addr2Balance = await token721A.balanceOf(account3.address);
            // expect(addr2Balance).to.equal(11);
        })
    });
    
});
