// utils
const hre = require('hardhat');
const { updateContractAddresses } = require('../utils/contractsManagement');
const { FacetCutAction, getSelectors } = require('../utils/diamond');

// const provider = new ethers.getDefaultProvider(process.env.NETWORK);
const network = hre.hardhatArguments.network;
async function main() {
  const adminAddress = '0x4281d6888D7a3A6736B0F596823810ffBd7D4808';
  const mrhbAddress = '0x45202955b5a2770A4dc526B6FB3634dDB275c8Df';
  const wbnbAddress = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd';
  const wethAddress = "0xc778417E063141139Fce010982780140Aa0cD5Ab";
  const adminCommissionPercentage = '1';

  //Address of the bidder and owner of whoile erc20 at first
  const signers = await hre.ethers.getSigners();
  const signer = signers[0];
  console.log("signer 0 is", signer.address)

  const address = "0x85E021c03161D591FB4768Bd5132822A18553b26";
  let erc20Address = "0xc778417E063141139Fce010982780140Aa0cD5Ab"


///////////////Media deployment
    const mediaFacet = await hre.ethers.getContractAt(
        'MediaFacet',
         address);

         console.log("Media facet is got")

    const erc721FactoryFacet = await hre.ethers.getContractAt(
        'ERC721FactoryFacet',
        address,
    );
///////////////Minting token from 721 contract
const token721 = await mediaFacet.mintTokenMedia(
    signer.address,
    0,
    "ERC721",
    1,
    "Sarkari",
    true,
    ["0x71593BAc0b4aE5278f784f0910f4829A103Ba7Cd", "0xCcd5FAA0C14641319f31eD72158d35BE6b9b90Da"],
    [500, 500],
    { gasLimit: 760000 }
  );

  console.log("token 0 minted")

  console.log("TOKEN URI", await erc721FactoryFacet.tokenURI(0))
  ///////////////

  //////royalty check for 1 eth
//   const r = await erc721FactoryFacet.royaltyInfo721(0, ethers.utils.parseEther('1.0'))
//    console.log("royality address of tokenId 0 is : ", r[0])
//    console.log("royality share for first account 1 eth is  : ", ethers.utils.formatEther(r[1][0]))
//    console.log("royality share for second account 1 eth is  : ", ethers.utils.formatEther(r[1][1]))

   ///////////////

  ///////////////checking toekn exists or not from media
  console.log("Token number 0 of 721 exists: ", await mediaFacet.istokenIdExistMedia(0,"ERC721"));
  ///////////////

  ///////////////set approved erc20 tokens from media
  await mediaFacet.connect(signer).setApprovedCryptoMedia(
    erc20Address,
    true
    );

  //console.log("Mock token is approved: ", await mediaFacet.getApprovedCryptoMedia(erc20Address));
  ///////////////

  ///////////////set platform commission fee from media
  await mediaFacet.connect(signer).setCommissionPercentageMedia(250);
  console.log("Platform commission fee: ", parseInt(await mediaFacet.getAdminCommissionPercentageMedia()));
  ///////////////

  /////////////// set collabortors from media
  await mediaFacet.connect(signer).setCollaboratorsMedia(
    address,
    0,
    ["0xa17C8DEbd6b9c2E993862255B992d45011dc898b", "0x71593BAc0b4aE5278f784f0910f4829A103Ba7Cd"],
    [1000,1000],
    { gasLimit: 760000 }
    );

  const collabTarget0 = await mediaFacet.getCollaboratorsMedia(address, 0); 
  // const collabTarget1 = await mediaFacet.getCollaboratorsMedia(souqNFTDiamond.address, 1); 

  console.log("Collaborators of token0 are ",  collabTarget0 ) 
  console.log("Shares of token0 are ", (collabTarget0["collabFraction"])) 
  ///////////////
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
