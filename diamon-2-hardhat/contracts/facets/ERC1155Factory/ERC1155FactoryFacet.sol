// SPDX-License-Identifier: MIT
/**
 * ERC1155FactoryFacet is used to mint NFTs that are ERC1155 compliant.
 * The mint function can only be called from souq Media contract.
 * It is initialized with name and symbol and default royalty.
 *
 */

pragma solidity ^0.8.0;

import "../ERC1155/ERC1155Facet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./LibERC1155FactoryStorage.sol";
import "../../libraries/LibURI.sol";



contract ERC1155FactoryFacet is ERC1155Facet {
    using Strings for uint256;

	modifier onlyMediaCaller() {
        require(msg.sender == s._mediaContract, "ERC721Factory: Unauthorized Access!");
        _;
    }

    function erc1155FactoryFacetInit(string memory name_, string memory symbol_) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        require(bytes(es.name).length == 0 && bytes(es.symbol).length == 0, "ALREADY_INITIALIZED");

        require(bytes(name_).length != 0 && bytes(symbol_).length != 0, "INVALID_PARAMS");

		require(msg.sender == ds.contractOwner, "Must own the contract.");
        es.name = name_;
        es.symbol = symbol_;
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI1155(uint256 tokenId, string memory _tokenURI) internal virtual {
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        es._tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @notice This function is used for minting new NFT in the market.
     * @param tokenId tokenId
     * @param creator address of the owner and creator of the NFT
     * @param tokenURI tokenURI
     * @param totalSupply copies of the NFT to be minted
     * @param royaltyReceiver an array of address that will recieve royalty. Max upto 5.
     * @param tokenRoyaltyInBips an array of royalty percentages. It should match the number of reciever addresses. Max upto 5.
     * @dev safemint() for minting the tokens.
     * @dev internal setTokenURI() to set the token URI for the minted token
     * @dev internal setTokenRoyalty() to set the rolayty at token level.
     */
    function mint(
        uint256 tokenId,
        address creator,
        uint256 totalSupply,
        string memory tokenURI,
        bool tokenRoyalty,
		address [] memory royaltyReceiver,
		uint96 [] memory tokenRoyaltyInBips

    ) external  onlyMediaCaller {
        if(tokenRoyalty){
            require(royaltyReceiver.length == tokenRoyaltyInBips.length, "ERC1155: the length of royalty addresses is not equal to the length of shares");
            require(royaltyReceiver.length <= 5, "ERC1155: too many royalty addresses has been set");
            //_setTokenRoyalty(tokenId,royaltyReceiver,tokenRoyaltyInBips);
        }

        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        es.nftToOwners[tokenId] = creator;
        es.nftToCreators[tokenId] = creator;
        _mint(creator, tokenId, totalSupply, "");
        _setTokenURI1155(tokenId, tokenURI);
    }

    /**
     * @notice This Method is used to Transfer Token
     * @dev This method is used while Direct Buy-Sell takes place
     *
     * @param _from Address of the Token Owner to transfer
     * @param _to Address of the Token receiver
     * @param _tokenID TokenID of the Token to transfer
     * @param _amount copies of Tokens to transfer, in case of Fungible Token transfer
     *
     * @return bool Transaction Status
     */

    function transfer(
        address _from,
        address _to,
        uint256 _tokenID,
        uint256 _amount
    ) external returns (bool) {
        require(_to != address(0x0), "ERC1155Factory: _to must be non-zero.");
        safeTransferFrom(_from, _to, _tokenID, _amount, "");
        return true;
    }

	/**
	 * @notice This function is used for burning an existing NFT.
	 * @dev _burn is an inherited function from ERC1155.
	 * @dev Destroys `amount` tokens of token type `tokenId` from `from` account
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
	 */
	function burn(address from, uint256 tokenId, uint256 amount) external  
	{
        _burn(from, tokenId, amount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator1155() internal pure virtual returns (uint96) {
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
    function _setTokenRoyalty1155(
        uint256 tokenId,
        address[] memory _receivers,
        uint96[] memory _feeNumerator
    ) internal virtual {
        require(_receivers[0] != address(0), "ERC1155 royalty: invalid receiver");
        require(_receivers.length <= 5, "ERC1155 royalty: Royalty recievers cannot be more than 5");
        require(_receivers.length == _feeNumerator.length, "ERC1155 royalty: Mismatch of Royalty Recxiever address and their share");
        uint totalFeeNumerator=0;
        for(uint i ; i < _feeNumerator.length; i++){
            totalFeeNumerator += _feeNumerator[i];
        }
        require(totalFeeNumerator <= _feeDenominator1155(), "ERC1155 royalty: royalty fee will exceed salePrice");
        
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        LibERC1155FactoryStorage.RoyaltyInfo memory royaltyInfo ;
        royaltyInfo.receiver = _receivers;
        royaltyInfo.royaltyFraction = _feeNumerator;
        es._tokenRoyaltyInfo[tokenId] = royaltyInfo; 
    }

    function royaltyInfo1155(uint256 _tokenID, uint256 _salePrice) public virtual returns (address[] memory , uint256[] memory) {
		LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();

        address[] memory receivers = es._tokenRoyaltyInfo[_tokenID].receiver;
        uint96[] memory fractions = es._tokenRoyaltyInfo[_tokenID].royaltyFraction;
        uint256[] memory royaltyAmount = new uint256[](fractions.length);

        for(uint i=0; i < fractions.length; i++){
            royaltyAmount[i] = (_salePrice * fractions[i]) / _feeDenominator1155();
        }
        return (receivers, royaltyAmount);
    }
}