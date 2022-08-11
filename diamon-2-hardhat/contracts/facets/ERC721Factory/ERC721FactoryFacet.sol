// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../ERC721/ERC721Facet.sol";
import "./LibERC721FactoryStorage.sol";
import "../../libraries/LibURI.sol";

contract ERC721FactoryFacet is ERC721Facet {
    using Strings for uint256;

    modifier onlyMediaCaller() {
        require(msg.sender == s._mediaContract, "ERC721Factory: Unauthorized Access!");
        _;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function erc721FactoryFacetInit(
        string memory name_,
        string memory symbol_
    ) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        require(bytes(es._name).length == 0 && bytes(es._symbol).length == 0);

        require(bytes(name_).length != 0 && bytes(symbol_).length != 0, "INVALID_PARAMS");

        require(msg.sender == ds.contractOwner, "Must own the contract.");

        es._name = name_;
        es._symbol = symbol_;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();
        es._tokenURIs[tokenId] = _tokenURI;
    }
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        string memory _tokenURI = es._tokenURIs[tokenId];
        return _tokenURI;
    }

    /* 
    @notice This function is used for minting 
     new NFT in the market.
    @dev 'msg.sender' will pass the '_tokenID' and 
     the respective NFT details.
    */
    function mint(
        uint256 _tokenID,
        address _creator,
        string memory _tokenURI
    ) external onlyMediaCaller {
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        es.nftToOwners[_tokenID] = _creator;
        es.nftToCreators[_tokenID] = _creator;
        _safeMint(_creator, _tokenID);
		_setTokenURI(_tokenID, _tokenURI);
    }

	function burn(uint256 tokenId) external 
	{
		LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        _burn(tokenId);
		delete es.nftToCreators[tokenId];
    }
 }
