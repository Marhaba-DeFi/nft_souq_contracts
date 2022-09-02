// Diamond deployment test - Ep2
//In this deployment we woul mint tokenId 0 of erc721FactoryFacet with royalty accounts
// set the commison fee and collaborators
const hre = require('hardhat');
const network = hre.hardhatArguments.network;
async function main() {

  //Address of the bidder and owner of whoile erc20 at first
  const signers = await hre.ethers.getSigners();
  const signer = signers[0];
  console.log("signer 0 is", signer.address)

  const diamondAddress = "";
  let erc20Address = ""


///////////////Media deployment
  const mediaFacet = await hre.ethers.getContractAt(
      'MediaFacet',
      diamondAddress);

        console.log("Media facet is got")

  const erc721FactoryFacet = await hre.ethers.getContractAt(
      'ERC721FactoryFacet',
      diamondAddress,
  );
        //checking the owner of the token
        const erc1155FactoryFacet = await hre.ethers.getContractAt(
          'ERC1155FactoryFacet',
          diamondAddress,
        );
    
        await erc1155FactoryFacet.connect(signer).setApprovalForAll(
          diamondAddress,
          true,
          { gasLimit: 7_600_000 }
          );

///////////////Minting token from 721 contract
//You should insert the royalty addresses at line 54
const token721 = await mediaFacet.mintTokenMedia(
    signer.address,
    0,
    "ERC721",
    1,
    "TESTURI",
    true,
    [""],
    [500],
    { gasLimit: 7_600_000 }
  );
  console.log("token 0 minted")

  ///////////////checking toekn exists or not from media
  ///////////////

  ///////////////set approved erc20 tokens from media
  await mediaFacet.connect(signer).setApprovedCryptoMedia(
    erc20Address,
    true,
    { gasLimit: 7_600_000 }
    );

  ///////////////

  ///////////////set platform commission fee from media
  await mediaFacet.connect(signer).setCommissionPercentageMedia(250,{ gasLimit: 7_600_000 });
  ///////////////

  /////////////// set collabortors from media
  //You should insert the collaborators addresses at line 81
  await mediaFacet.connect(signer).setCollaboratorsMedia(
    diamondAddress,
    0,
    [""],
    [1000],
    { gasLimit: 7_600_000 }
    );  
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
