// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC1155Factory is Pausable, ERC1155, ERC2981, Ownable {

    using Counters for Counters.Counter;
	Counters.Counter private _tokenIdCounter;

    // Mapping from token ID to creator address
    mapping(uint256 => address) public _creators;
    mapping (uint256 => string) tokenURIs;
    
    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` and default royalty to the token collection.
     * @notice default royalty is optional. DefaultRoyalty is set, if the flag is true.
     */
    constructor(
        string memory name_, 
        string memory symbol_,
        bool defaultRoyalty,
        address[] memory royaltyReceiver, 
		uint96[] memory royaltyFeesInBips
    ) ERC1155(name_, symbol_) {
        bytes memory validateName = bytes(name_); // Uses memory
        bytes memory validateSymbol = bytes(symbol_);
        require( validateName.length != 0 && validateSymbol.length != 0, "ERC1155: Choose a name and symbol");
        if(defaultRoyalty){
            // At least one royaltyReceiver is required.
            require(royaltyReceiver.length > 0, "No Royalty details provided");
            // Check on the maximum size over which the for loop will run over.
            require(royaltyReceiver.length <= 5, "Too many royalty recievers details");
            //Check the length of receiver and fees should match
            require(royaltyReceiver.length == royaltyFeesInBips.length, "Mismatch of Royalty recievers and their fees");
            _setDefaultRoyalty(royaltyReceiver, royaltyFeesInBips);
        }
    }

    // function _name() internal view virtual returns (string memory) {
    //     return name;
    // }

    // function _symbol() internal view virtual returns (string memory) {
    //     return symbol;
    // }

/**
* @dev due to multiple copies of ERC1155 tokens, this function can only be executed once while minting.
 */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        tokenURIs[tokenId] = _tokenURI;
    }

	function uri(uint256 tokenId) override public view returns (string memory) {
        return(tokenURIs[tokenId]);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

	/**
     * @notice This function is used for minting new NFT in the market.
     * @param creator address of the owner and creator of the NFT
     * @param tokenURI tokenURI
     * @param copies copies of the NFT to be minted
     * @param royaltyReceiver an array of address that will recieve royalty. Max upto 5.
     * @param tokenRoyaltyInBips an array of royalty percentages. It should match the number of reciever addresses. Max upto 5.
     * @dev safemint() for minting the tokens.
     * @dev internal setTokenURI() to set the token URI for the minted token
     * @dev internal setTokenRoyalty() to set the rolayty at token level.
     */
    function mint(
			address creator, 
			string memory tokenURI,  
			uint256 copies, 
            bool tokenRoyalty,
			address[] memory royaltyReceiver, 
		    uint96[] memory tokenRoyaltyInBips
		) public onlyOwner returns(uint256, uint256) {
            uint256 tokenId = _tokenIdCounter.current();
            _mint(creator, tokenId, copies, "");
            _setTokenURI(tokenId, tokenURI);
            //If Author royalty is set to true
            if(tokenRoyalty){
                // At least one royaltyReceiver is required.
                require(royaltyReceiver.length > 0, "No Royalty details provided");
                // Check on the maximum size over which the for loop will run over.
                require(royaltyReceiver.length <= 5, "Too many royalty recievers details");
                //Check the length of receiver and fees should match
                require(royaltyReceiver.length == tokenRoyaltyInBips.length, "Mismatch of Royalty recievers and their fees");
                _setTokenRoyalty(tokenId, royaltyReceiver, tokenRoyaltyInBips);
            }
            //Increment tokenId
            _tokenIdCounter.increment();
            return(tokenId, copies);
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
    function burn(address _from, 
        uint256 _tokenId, 
        uint256 _amount
    ) external {
        require(balanceOf(msg.sender, _tokenId) != 0, "ERC1155: Not the owner of this token");
        require(balanceOf(msg.sender, _tokenId) >= _amount, "ERC1155: Not enough quantity to burn");
        _burn(_from, _tokenId, _amount);
    }

	   /**
     * @notice This Method is used to Transfer Token
     * @dev This method is used while Direct Buy-Sell takes place
     *
     * @param _from Address of the Token Owner to transfer
     * @param _to Address of the Token receiver
     * @param _tokenId TokenID of the Token to transfer
     * @param _copies copies of Tokens to transfer, in case of Fungible Token transfer
     *
     * @return bool Transaction Status
     */
    function transfer(
		address _from, 
		address _to, 
		uint256 _tokenId, 
		uint256 _copies
	) external returns (bool) {
        require(balanceOf(_from, _tokenId) >= _copies, "ERC1155: Not enough copies");
        safeTransferFrom(_from, _to, _tokenId, _copies, "");
        return true;
    }

    function supportsInterface(bytes4 interfaceId) 
		public 
		view 
		virtual 
		override(ERC1155, ERC2981) 
		returns (bool) 
	{
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}