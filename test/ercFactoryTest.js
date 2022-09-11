// test/ERC721-test.js
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const parseEther = ethers.utils.parseEther;
const _INTERFACE_ID_ERC165 = '0x01ffc9a7';
const _INTERFACE_ID_ROYALTIES_EIP2981 = '0x2a55205a';
const _INTERFACE_ID_ERC721 = '0x80ac58cd';

describe("ERCFactory contracts", function () {
    let ERC721Factory, ERC1155Factory, ERC721AFactory, ERC721RFactory, ERC2981;
    let token721, token1155, token721A, token721R, erc2981;

    let account2;
    let account3;

    let name='Artwork Contract';
    let symbol='ART';
    let copies = 10;
    let defaultRoyalty = true;
    let royaltyReceiver = ["0xaB856c0f5901432DEb88940C9423c555814BC0fd"];
    let royaltyFeesInBips = [1000];
    let mintSupply = 1000;
    let mintingPrice = "1";
    let refundTime = 24 * 60 * 60 * 45;
    let maxMintPerUser = 5;
    let alice="0x71593BAc0b4aE5278f784f0910f4829A103Ba7Cd";
    let bob= "0x032779f45b50d0Fa6F55692C18548DfC6ca1E58F";
    let dave="0x5c381DF64b818E54E2ff78FeD0036Ea9a984B028";
    let carol="0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
    let frank="0xCcd5FAA0C14641319f31eD72158d35BE6b9b90Da";
    let jane="0xAEB8Fa0Bf852f412CaE5897Cf2E24E7E9aC60944";
    let blockDeployTimeStamp;
	const ADDRESS_ZERO = ethers.constants.AddressZero;


    const mineSingleBlock = async () => {
        await ethers.provider.send("hardhat_mine", [
          ethers.utils.hexValue(1).toString(),
        ]);
      };
      
      async function simulateNextBlockTime(baseTime, changeBy) {
        const bi = BigNumber.from(baseTime);
        await ethers.provider.send("evm_setNextBlockTimestamp", [
          ethers.utils.hexlify(bi.add(changeBy)),
        ]);
        await mineSingleBlock();
      }

    beforeEach(async function () {

        [owner, account2,account3] = await ethers.getSigners();
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
            ethers.utils.parseEther(mintingPrice),
            //mintingPrice,
            refundTime,
            maxMintPerUser);

       
        await token721R.deployed();
        blockDeployTimeStamp = (await token721R.provider.getBlock("latest"))
        .timestamp;

        const saleActivePub = await token721R.publicSaleActive();
        expect(saleActivePub).to.be.equal(false);
        await token721R.togglePublicSaleStatus();
        const publicSaleActive = await token721R.publicSaleActive();
        expect(publicSaleActive).to.eq(true);
      
        const saleActivePre = await token721R.presaleActive();
        expect(saleActivePre).to.be.equal(false);
        await token721R.togglePresaleStatus();
        const presaleActive = await token721R.presaleActive();
        expect(presaleActive).to.eq(true);

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
            expect(await
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
            expect(await
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

	describe('Royalties', async () => {
        it('ERC721factory has all the right interfaces', async function () {
            expect(
                await token721.supportsInterface(
                    _INTERFACE_ID_ERC165,
                ),
                'Error Royalties 165',
            ).to.be.true;

            expect(
                await token721.supportsInterface(
                    _INTERFACE_ID_ROYALTIES_EIP2981,
                ),
                'Error Royalties 2981',
            ).to.be.true;

            expect(
                await token721.supportsInterface(
                    _INTERFACE_ID_ERC721,
                ),
                'Error Royalties 721',
            ).to.be.true;
        });

		it('ERC721factory throws if royalties more than 100%', async function () {
            const tx = token721.safeMint(
				alice,
				true,
				[alice],
				[10001]  // 100.01%
			)

            await expect(tx).to.be.revertedWith('ERC2981: royalty fee will exceed salePrice');
        });
	})

    describe("ERC721R PublicMint", function () {
        it("Should not be able to mint when `Public sale is not active`", async function () {
            await token721R.togglePublicSaleStatus();
            await expect(
                token721R
                .connect(account2)
                .publicSaleMint(1, { value: parseEther(mintingPrice) })
            ).to.be.revertedWith("Public sale is not active");
        });
      
        it("Should not be able to mint when `Not enough eth sent`", async function () {
            await expect(
                token721R.connect(account2).publicSaleMint(1, { value: 0 })
            ).to.be.revertedWith("Not enough eth sent");
        });
      
        it("Should not be able to mint when `Max mint supply reached`", async function () {
            await token721R.provider.send("hardhat_setStorageAt", [
                token721R.address,
                "0x0",
                ethers.utils.solidityPack(["uint256"], [mintSupply]), // 8000
            ]);
            await expect(
                token721R
                .connect(account2)
                .publicSaleMint(1, { value: parseEther(mintingPrice) })
            ).to.be.revertedWith("Max mint supply reached");
        });
      
        it("Should not be able to mint when `Over mint limit`", async function () {
            await token721R
                .connect(account2)
                .publicSaleMint(5, { value: parseEther("5") });
            await expect(
                token721R
                .connect(account2)
                .publicSaleMint(1, { value: parseEther(mintingPrice) })
            ).to.be.revertedWith("Over mint limit");
        });
    });

    describe("ERC721R PreSaleMint", function () {

        it("Should not be able to mint when `Presale is not active`", async function () {
            await token721R.togglePresaleStatus();
            await expect(
              token721R
                .connect(account2)
                .preSaleMint(1, { value: parseEther(mintingPrice) })
            ).to.be.revertedWith("Presale is not active");
        });
        
        it("Should not presale mint when `Address not whitelisted`", async function () {
            await token721R.provider.send("hardhat_setBalance", [
                owner.address,
                "0xffffffffffffffffffff",
            ]);
            // await token721R.togglePresaleStatus();
            await token721R.setWhitelistEnabled(true);
            await expect(
                token721R
                .connect(account2)
                .preSaleMint(1, { value: parseEther(mintingPrice) })
            ).revertedWith("Address not whitelisted");
            expect(await token721R.balanceOf(account2.address)).to.be.equal(0);
        });

        it("Should presale mint when `Address is whitelisted`", async function () {
            await token721R.provider.send("hardhat_setBalance", [
                owner.address,
                "0xffffffffffffffffffff",
            ]);
            // await token721R.togglePresaleStatus();
            await token721R.setWhitelistEnabled(true);
            await token721R.setWhitelist([account2.address]);
            expect( await
                token721R
                .connect(account2)
                .preSaleMint(1, { value: parseEther(mintingPrice) })
            )
            const ownerOfToken0 = await token721R.ownerOf(0);
            expect(ownerOfToken0).to.equals(account2.address)  
        });

        it("Should not be able to mint when `Not enough eth sent`", async function () {
            await expect(
                token721R.connect(account2).preSaleMint(1, { value: 0 })
            ).to.be.revertedWith("Not enough eth sent");
        });
        
        it("Should not be able to mint when `Max mint supply reached`", async function () {
            await token721R.provider.send("hardhat_setStorageAt", [
                token721R.address,
                "0x0",
                ethers.utils.solidityPack(["uint256"], [mintSupply]), // 8000
            ]);
            await expect(
                token721R
                    .connect(account2)
                    .preSaleMint(1, { value: parseEther(mintingPrice) })
            ).to.be.revertedWith("Max mint supply reached");
        });
        
        it("Should not be able to mint when `Over mint limit`", async function () {
            await token721R
                .connect(account2)
                .preSaleMint(5, { value: ethers.utils.parseEther("5") });
            await expect(
                token721R
                    .connect(account2)
                    .preSaleMint(1, { value: ethers.utils.parseEther(mintingPrice) })
            ).to.be.revertedWith("Over mint limit");
        });
    });

    describe("ERC721R Refund", function () {
        it("Should be store correct tokenId in refund", async function () {
            await token721R
            .connect(account2)
            .publicSaleMint(1, { value: parseEther(mintingPrice) });
            await token721R.connect(account2).refund([0]);
            expect(await token721R.hasRefunded(0)).to.be.true;
        });
        
        it("Should be revert `Freely minted NFTs cannot be refunded`", async function () {
            await token721R.ownerMint(1);
            expect(await token721R.isOwnerMint(0)).to.be.equal(true);
            await expect(token721R.refund([0])).to.be.revertedWith(
                "Freely minted NFTs cannot be refunded"
            );
        });
        
        it("Should be refund NFT in 45 days", async function () {
            const refundEndTime = await token721R.getRefundGuaranteeEndTime();
        
            await token721R
            .connect(account2)
            .publicSaleMint(1, { value: parseEther(mintingPrice) });
        
            await token721R.provider.send("evm_setNextBlockTimestamp", [
                refundEndTime.toNumber(),
            ]);
        
            await token721R.connect(account2).refund([0]);
        });
        
        it("Should not be refunded when `Not token owner`", async function () {
            await token721R.ownerMint(1);
            expect(await token721R.isOwnerMint(0)).to.be.equal(true);
            await expect(
            token721R.connect(account2).refund([0])
            ).to.be.revertedWith("Not token owner");
        });
        
        it("Should not be refunded NFT twice `Already refunded`", async function () {
            // update refund address and mint NFT from refund address
            await token721R.setRefundAddress(account2.address);

            await token721R
            .connect(account3)
            .publicSaleMint(1, { value: parseEther(mintingPrice) });

            await token721R
            .connect(account2)
            .publicSaleMint(3, { value: parseEther("3") });
        
            await token721R.connect(account2).refund([1]);

            await expect(
            token721R.connect(account2).refund([1])
            ).to.be.revertedWith("Already refunded");
        });
        
        it("Should not be refund NFT expired after 45 days `Refund expired`", async function () {
            const refundEndTime = await token721R.getRefundGuaranteeEndTime();
        
            await token721R
            .connect(account2)
            .publicSaleMint(1, { value: parseEther(mintingPrice) });
        
            await simulateNextBlockTime(refundEndTime, +1);
        
            await expect(token721R.connect(account2).refund([0])).to.revertedWith(
                "Refund expired"
            );
        });
    });

    describe("ERC721R Owner", function () {
        it("Should be able to mint", async function () {
          await token721R.ownerMint(1);
          expect(await token721R.balanceOf(owner.address)).to.be.equal(1);
          expect(await token721R.ownerOf(0)).to.be.equal(owner.address);
        });
      
        it("Should not be able to mint when `Max mint supply reached`", async function () {
          await token721R.provider.send("hardhat_setStorageAt", [
            token721R.address,
            "0x0",
            ethers.utils.solidityPack(["uint256"], [mintSupply]), // 8000
          ]);
          await expect(token721R.ownerMint(1)).to.be.revertedWith(
            "Max mint supply reached"
          );
        });
      
        it("Should not be able to withdraw when `Refund period is not over`", async function () {
          await expect(token721R.connect(owner).withdraw()).to.revertedWith(
            "Refund period not over"
          );
        });
      
        it("Should be able to withdraw after refundEndTime", async function () {
          const refundEndTime = await token721R.getRefundGuaranteeEndTime();
      
          await token721R
            .connect(account2)
            .publicSaleMint(1, { value: parseEther(mintingPrice) });
      
          await simulateNextBlockTime(refundEndTime, +11);
      
          await token721R.provider.send("hardhat_setBalance", [
            owner.address,
            "0x8e1bc9bf040000", // 0.04 ether
          ]);
          const ownerOriginBalance = await token721R.provider.getBalance(
            owner.address
          );
          // first check the owner balance is less than 0.1 ether
          expect(ownerOriginBalance).to.be.lt(parseEther("1"));
      
          await token721R.connect(owner).withdraw();
      
          const contractVault = await token721R.provider.getBalance(
            token721R.address
          );
          const ownerBalance = await token721R.provider.getBalance(
            owner.address
          );
      
          expect(contractVault).to.be.equal(parseEther("0"));
          // the owner origin balance is less than 0.1 ether
          expect(ownerBalance).to.be.gt(parseEther("1"));
        });
    });

    describe("ERC721R Toggle", function () {
    it("Should be able to call toggleRefundCountdown and refundEndTime add `refundPeriod` days.", async function () {
    const beforeRefundEndTime = (
      await token721R.getRefundGuaranteeEndTime()
    ).toNumber();

    await token721R.provider.send("evm_setNextBlockTimestamp", [
      beforeRefundEndTime,
    ]);

    await token721R.toggleRefundCountdown();

    const afterRefundEndTime = (
      await token721R.getRefundGuaranteeEndTime()
    ).toNumber();

    expect(afterRefundEndTime).to.be.equal(beforeRefundEndTime + refundTime);
  });

  it("Should not be able to call togglePresaleStatus", async function () {
    await token721R.togglePresaleStatus();
    expect(await token721R.presaleActive()).to.be.false;
  });

  it("Should not be able to call togglePublicSaleStatus", async function () {
    await token721R.togglePublicSaleStatus();
    expect(await token721R.publicSaleActive()).to.be.false;
  });
    });

    describe("ERC721R Setter", function () {
    it("Should be able to call setRefundAddress", async function () {
      await token721R.setRefundAddress(account2.address);
      expect(await token721R.refundAddress()).to.be.equal(account2.address);
    });
  
    });

    describe("ERC 721R Aggregation", function () {
        it("Should be able to mint and request a refund", async function () {
          await token721R
            .connect(account2)
            .publicSaleMint(1, { value: parseEther(mintingPrice) });
      
          const balanceAfterMint = await token721R.balanceOf(account2.address);
          expect(balanceAfterMint).to.eq(1);
      
          const endRefundTime = await token721R.getRefundGuaranteeEndTime();
          await simulateNextBlockTime(endRefundTime, -10);
      
          await token721R.connect(account2).refund([0]);
      
          const balanceAfterRefund = await token721R.balanceOf(account2.address);
          expect(balanceAfterRefund).to.eq(0);
      
          const balanceAfterRefundOfOwner = await token721R.balanceOf(
            owner.address
          );
          expect(balanceAfterRefundOfOwner).to.eq(1);
        });
    });
      
    describe("ERC 721R Check ERC721R Constant & Variables", function () {
        it(`Should maxMintSupply = ${mintSupply}`, async function () {
          expect(await token721R.maxMintSupply()).to.be.equal(mintSupply);
        });

        it(`Should mintPrice = ${mintingPrice}`, async function () {
            expect(await token721R.mintPrice()).to.be.equal(
            ethers.utils.parseEther(mintingPrice)
            );
          });
      
        it(`Should refundPeriod ${refundTime}`, async function () {
          expect(await token721R.refundPeriod()).to.be.equal(refundTime);
        });
      
        it(`Should maxUserMintAmount ${maxMintPerUser}`, async function () {
          expect(await token721R.maxUserMintAmount()).to.be.equal(
            maxMintPerUser
          );
        });
      
        it("Should refundEndTime is same with block timestamp in first deploy", async function () {
          const refundEndTime = await token721R.getRefundGuaranteeEndTime();
          expect(blockDeployTimeStamp + refundTime).to.be.equal(refundEndTime);
        });
      
        it(`Should refundGuaranteeActive = true`, async function () {
          expect(await token721R.isRefundGuaranteeActive()).to.be.true;
        });
    });


});

