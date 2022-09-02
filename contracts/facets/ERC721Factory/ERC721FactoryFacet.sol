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
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI721(uint256 tokenId, string memory _tokenURI) internal virtual {
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
        bool tokenRoyalty,
		address [] memory royaltyReceiver,
		uint96 [] memory tokenRoyaltyInBips
    ) external onlyMediaCaller {
        if(tokenRoyalty){
            require(royaltyReceiver.length == tokenRoyaltyInBips.length, "ERC721: the length of royalty addresses is not equal to the length of shares");
            require(royaltyReceiver.length <= 5, "ERC721: too many royalty addresses has been set");
            _setTokenRoyalty721(tokenId,royaltyReceiver,tokenRoyaltyInBips);
        }
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        es.nftToOwners[tokenId] = creator;
        es.nftToCreators[tokenId] = creator;
        _safeMint(creator, tokenId);
		_setTokenURI721(tokenId, _tokenURI);
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

	/**
	 * @notice This function is used for checking existance of an NFT.
	 * @dev _tokenExists calls _exists function (which is internal) from ERC721.
	 * Requirements:
     *
	 */
    function _tokenExists(uint256 tokenId) public view virtual returns(bool) {
        return(_exists(tokenId));
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator721() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty721(
        uint256 tokenId,
        address[] memory _receivers,
        uint96[] memory _feeNumerator
    ) internal virtual {
        require(_receivers[0] != address(0), "ERC2981: invalid receiver");
        require(_receivers.length <= 5, "Royalty recievers cannot be more than 5");
        require(_receivers.length == _feeNumerator.length, "Mismatch of Royalty Recxiever address and their share");
        uint totalFeeNumerator=0;
        for(uint i ; i < _feeNumerator.length; i++){
            totalFeeNumerator += _feeNumerator[i];
        }
        require(totalFeeNumerator <= _feeDenominator721(), "ERC2981: royalty fee will exceed salePrice");
        
        LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();
        LibERC721FactoryStorage.RoyaltyInfo memory royaltyInfo ;
        royaltyInfo.receiver = _receivers;
        royaltyInfo.royaltyFraction = _feeNumerator;
        es._tokenRoyaltyInfo[tokenId] = royaltyInfo; 
    }

    function royaltyInfo721(uint256 _tokenID, uint256 _salePrice) public view virtual returns (address[] memory , uint256[] memory ) {
		LibERC721FactoryStorage.ERC721FactoryStorage storage es = LibERC721FactoryStorage.erc721FactoryStorage();

        address[] memory receivers = es._tokenRoyaltyInfo[_tokenID].receiver;
        uint96[] memory fractions = es._tokenRoyaltyInfo[_tokenID].royaltyFraction;
        uint256[] memory royaltyAmount = new uint256[](fractions.length);

        for(uint i=0; i < royaltyAmount.length; i++){
            royaltyAmount[i] = (_salePrice * fractions[i]) / _feeDenominator721();
        }
        return (receivers, royaltyAmount);
    }
}