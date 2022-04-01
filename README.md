# Souq NFT

this repo contain the contracts for the Souq NFT

Souq NFT contracts implement [the second implementation](https://github.dev/mudgen/diamond-2-hardhat) of the [diamond proposal](https://github.com/mudgen/diamond-2-hardhat)

## structure

```
/contracts
    /SouqNFTDiamond.sol
    /facets
        /ERC721
        /ERC721Factory
        /ERC1155
        /ERC1155Factory
        /Market
        /Media

/scripts
    /deploy.js
    /updateDiamond.js

/tasks
    /generateDiamondABI.js

/test
    /Media.test.js
```
