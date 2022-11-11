// test/SBTFactory.js
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const parseEther = ethers.utils.parseEther;


describe("SoulBoundToken Contracts", function () {
    let SBTFactory;
    let tokenSBT;
    let expdate = 1;
    let ipfsdotcom;
    let newExpiration;
    let _tokenId;
    // let _uri = 1664936268;
    //userAddress ='0x01ffc9a7';
    // let _expires = 1764936268;
    let maxMintLimit = 5;
    let blockDeployTimeStamp;
    let _recipient, account1, account2, account3, account4, account5, account6;

    let name = 'Artwork Contract';
    let symbol = 'ART';

    // const mineSingleBlock = async () => {
    //     await ethers.provider.send("hardhat_mine", [
    //         ethers.utils.hexValue(1).toString(),
    //     ]);
    // };

    // async function simulateNextBlockTime(baseTime, changeBy) {
    //     const bi = BigNumber.from(baseTime);
    //     await ethers.provider.send("evm_setNextBlockTimestamp", [
    //         ethers.utils.hexlify(bi.add(changeBy)),
    //     ]);
    //     await mineSingleBlock();
    // }

    beforeEach(async function () {
        [_recipient, owner, account1, account2, account3, account4, account5, account6] = await ethers.getSigners();
        // console.log("owner: ", owner.address);

        SBTFactory = await ethers.getContractFactory("SBTFactory")
        tokenSBT = await SBTFactory.connect(owner).deploy(
            name,
            symbol,
        );

        await tokenSBT.deployed();
        blockDeployTimeStamp = (await tokenSBT.provider.getBlock("latest"))
            .timestamp;
    });

    // You can nest describe calls to create subsections.
    describe("Deployment", function () {
        it("Should have the correct name and symbol ", async function () {
            expect(await tokenSBT.name()).to.equal(name);
            expect(await tokenSBT.symbol()).to.equal(symbol);
        });
    });

    describe('SBTFactory issueOne', async function () {
        it('IssueOne cannot be done if whitelist is enabled and the address is not whitelisted', async () => {
            await tokenSBT.setWhitelistEnabled(true);
            await tokenSBT.setWhitelist([account2.address, account3.address]);
            const tx = tokenSBT.connect(owner).issueOne(
                _recipient.address,
                "ipfsdotcom",
                3888000
            )
            await expect(tx).to.be.revertedWith('Address not whitelisted')
        })


        it('IssueOne can be done by owner if whitelist is not enabled ', async () => {
            await tokenSBT.setWhitelistEnabled(false);
            expect(await
                tokenSBT.connect(owner).issueOne(
                    _recipient.address,
                    "ipfsdotcom",
                    3888000
                )
            )
            // check owner
            const ownerOfToken0 = await tokenSBT.ownerOf(0);
            expect(ownerOfToken0).to.equals(_recipient.address)
        })


    })

    describe('SBTFactory issueMany', async function () {
        it('IssueMany cannot be done if whitelist is enabled and the address is not whitelisted', async () => {
            await tokenSBT.setWhitelistEnabled(true);
            await tokenSBT.setWhitelist([account5.address, account6.address]);
			let receipients = []
			let urls = []
			let expires = []

			for (let i = 0 ;i < maxMintLimit ; i++){
				receipients.push(_recipient.address)
				urls.push("ipfsdotcom")
				expires.push(353535353)
			}
            const tx = tokenSBT.connect(owner).issueMany(
                receipients,
                urls,
                expires
            )
            await expect(tx).to.be.revertedWith('Address not whitelisted')
        })

		it('IssueMany cannot be done for more then the maxMintLimit limit', async () => {
			await tokenSBT.setWhitelistEnabled(true);
			await tokenSBT.setWhitelist([owner.address]);
			let receipients = []
			let urls = []
			let expires = []

			for (let i = 0 ;i < maxMintLimit + 1 ; i++){
				receipients.push(_recipient.address)
				urls.push("ipfsdotcom")
				expires.push(353535353)
			}
			const tx = tokenSBT.connect(owner).issueMany(
				receipients,
				urls,
				expires
			)
			await expect(tx).to.be.revertedWith('SBT: Number of reciepient exceed the max mint limit')
		})
        it('IssueMany can be done by owner if whitelist is not enabled ', async () => {
            await tokenSBT.setWhitelistEnabled(false);
            expect(await
                tokenSBT.connect(owner).issueMany(
                    [_recipient.address,
                    account1.address,
                    account2.address,
                    account3.address,
                    account4.address],
                    ["ipfsdotcom", "ipfsdotcom", "ipfsdotcom", "ipfsdotcom", "ipfsdotcom"],
                    [353535353, 353535353, 353535353, 353535353, 353535353]
                )
            )
            // check owner
            const ownerOfToken0 = await tokenSBT.ownerOf(0);
            const ownerOfToken1 = await tokenSBT.ownerOf(1);
            const ownerOfToken2 = await tokenSBT.ownerOf(2);
            const ownerOfToken3 = await tokenSBT.ownerOf(3);
            const ownerOfToken4 = await tokenSBT.ownerOf(4);
            expect(ownerOfToken0).to.equals(_recipient.address)
            expect(ownerOfToken1).to.equals(account1.address)
            expect(ownerOfToken2).to.equals(account2.address)
            expect(ownerOfToken3).to.equals(account3.address)
            expect(ownerOfToken4).to.equals(account4.address)

        })


    })

    describe('SBT burn by whitelisted address', async function () {
        it('SBT Burn', async () => {
            await tokenSBT.setWhitelistEnabled(true);
            await tokenSBT.setWhitelist([account2.address]);
            expect(await
                tokenSBT.connect(account2).issueOne(
                    account2.address,
                    "ipfsdotcom",
                    388
                )
            )
            // check owner
            const ownerOfToken0 = await tokenSBT.ownerOf(0);
            expect(ownerOfToken0).to.equals(account2.address)
            await tokenSBT.connect(account2).burn(0);

        })
    });

    describe('SBT Expiry check', async function () {
        it('SBT Get Expiry date', async () => {
            await tokenSBT.setWhitelistEnabled(true);
            await tokenSBT.setWhitelist([account2.address]);
            await tokenSBT.connect(account2).issueOne(
                account2.address,
                "ipfsdotcom",
                1
            )

            const expDate = await tokenSBT.getExpDate(0);
            //  expect(ownerOfToken0).to.equals(account2.address)
            expect(expDate[0]).to.be.equal(1);
            expect(expDate[1]).to.be.equal(account2.address);

        })
    });

    describe('SBT Extend expiry check', async function () {
        it('SBT Entend Expiry', async () => {
            await tokenSBT.setWhitelistEnabled(true);
            await tokenSBT.setWhitelist([account2.address]);
            await tokenSBT.connect(account2).issueOne(
                account2.address,
                "ipfsdotcom",
                1664904067
            )
            expect(await tokenSBT.extend(1696440067, 0))
                .emit(tokenSBT, "extendExpiry").withArgs(newExpiration, _tokenId);
        })
    });

});
