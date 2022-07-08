// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Souq1155 is Pausable, ERC1155, ERC2981 {
    address private _mediaContract;
    address public owner;
    uint96 royaltyFeesInBips;
    address royaltyAddress;


    // Mapping from token ID to creator address
    mapping(uint256 => address) public _creators;
    mapping (uint256 => string) tokenURIs;

    constructor(
        string memory name_, 
        string memory symbol_,
        uint96 _royaltyFeesInBips,
        address _royaltyReciever
    ) ERC1155(name_, symbol_) 
	{
        owner = msg.sender;
        bytes memory validateName = bytes(name_); // Uses memory
        bytes memory validateSymbol = bytes(symbol_);
        require( validateName.length != 0 && validateSymbol.length != 0, "ERC1155: Choose a name and symbol");
        _setDefaultRoyalty(_royaltyReciever, _royaltyFeesInBips);
    }

    modifier onlyOwner ()
	{
        require(msg.sender == owner || msg.sender == _mediaContract, "Not the owner");
        _;
    }

    function configureMedia(address _mediaContractAddress) external onlyOwner
	{
        // TODO: Only Owner Modifier
        require(
            _mediaContractAddress != address(0),
            "ERC1155Factory: Invalid Media Contract Address!"
        );
        require(
            _mediaContract == address(0),
            "ERC1155Factory: Media Contract Already Configured!"
        );

        _mediaContract = _mediaContractAddress;
    }

    function _name() internal view virtual returns (string memory) 
	{
        return name;
    }

    function _symbol() internal view virtual returns (string memory) 
	{
        return symbol;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner 
	{
        tokenURIs[tokenId] = _tokenURI;
    }
	function uri(uint256 tokenId) override public view returns (string memory) 
	{
        return(tokenURIs[tokenId]);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address _to, string memory _tokenURI, uint256 _id, uint256 _copies, address royaltyReceiver, uint96 _tokenRoyaltyInBips)
        public onlyOwner returns(uint256, uint256) 
	{
        _mint(_to, _id, _copies, "");
        setTokenURI(_id, _tokenURI);
        setTokenRoyaltyInfo(_id, royaltyReceiver, _tokenRoyaltyInBips);
		_creators[_id] = _to;
        return(_id, _copies);
    }

    function burn(address _from, uint256 _tokenId, uint256 _amount) external onlyOwner  
	{
        _burn(_from, _tokenId, _amount);
        delete _creators[_tokenId];
    }

    function transfer(
		address _owner, 
		address _reciever, 
		uint256 _tokenId, 
		uint256 _copies
	) external returns (bool)
	{
        safeTransferFrom(_owner, _reciever, _tokenId, _copies, "");
        return true;
    }

    function _beforeTokenTransfer(
		address operator, 
		address from, 
		address to, 
		uint256[] memory ids, 
		uint256[] memory amounts, 
		bytes memory data
	)
        internal
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setTokenRoyaltyInfo(
		uint256 _tokenId,
		address _receiver, 
		uint96 _royaltyFeesInBips
	) public onlyOwner 
	{
        _setTokenRoyalty(_tokenId, _receiver, _royaltyFeesInBips);
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