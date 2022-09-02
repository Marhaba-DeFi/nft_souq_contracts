const { expect } = require("chai");

describe("ERC2981 Royalty contract", function () {
	let ERC2981;
    let erc2981;
	let alice="0x71593BAc0b4aE5278f784f0910f4829A103Ba7Cd";
	let bob= "0x032779f45b50d0Fa6F55692C18548DfC6ca1E58F";
	let dave="0x5c381DF64b818E54E2ff78FeD0036Ea9a984B028";
	let carol="0x70997970C51812dc3A010C7d01b50e0d17dc79C8";
	let frank="0xCcd5FAA0C14641319f31eD72158d35BE6b9b90Da";
	let jane="0xAEB8Fa0Bf852f412CaE5897Cf2E24E7E9aC60944";

	beforeEach(async function () {
		ERC2981 = await ethers.getContractFactory("ERC2981")
		erc2981 = await ERC2981.deploy();
	})

	describe('Set royalty', async function () {
		it('set default royalty with more than 5 royalty recievers', async () => {
		  	// alice mint a token
			  await erc2981.setDefaultRoyalty(
				[alice, bob, dave, carol, frank, jane],
				["250", "500","250","250","500","250"]
			  )
			// check owner
			await expect(
				erc2981.connect(alice)._setDefaultRoyalty(
				)
			  ).to.be.revertedWith("Too many Collaborators")	
		})
	})
})