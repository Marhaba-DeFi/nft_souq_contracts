// SPDX-License-Identifier: MIT
/**
 * ERC721FactoryFacet is used to mint NFTs that are ERC721 compliant.
 * The mint function can only be called from souq Media contract. 
 * It is initialized with name and symbol and default royalty. 
 * 
 */

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
     * @dev Initializes the contract by setting a `name` and a `symbol` and default royalty to the token collection.
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
		//setDefaultRoyalty
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

    /**
	 * @notice This function is used for minting new NFT in the market.
     * @param tokenId tokenId
	 * @param creator address of the owner and creator of the NFT
	 * @param _tokenURI tokenURI
	 * @param royaltyReceiver an array of address that will recieve royalty. Max upto 5.
	 * @param tokenRoyaltyInBips an array of royalty percentages. It should match the number of reciever addresses. Max upto 5.
	 * @dev safemint() for minting the tokens.
	 * @dev internal setTokenURI() to set the token URI for the minted token
	 * @dev internal setTokenRoyalty() to set the rolayty at token level. 
	 */
    
    function mint(
        uint256 tokenId,
        address creator,
        string memory _tokenURI,
		address [] memory royaltyReceiver,
		uint96 [] memory tokenRoyaltyInBips
    ) external onlyMediaCaller {
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        es.nftToOwners[tokenId] = creator;
        es.nftToCreators[tokenId] = creator;
        _safeMint(creator, tokenId);
		_setTokenURI(tokenId, _tokenURI);
		//setTokenRoyalty
    }

	/**
	 * @notice This function is used for burning an existing NFT.
	 * @dev _burn is an inherited function from ERC721.
	 * Requirements:
     *
     * - `tokenId` must exist.
	 */
	function burn(uint256 tokenId) external {
		LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        _burn(tokenId);
		delete es.nftToCreators[tokenId];
    }
}
