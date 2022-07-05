// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract Souq1155 is Pausable, ERC1155, ERC2981 {
    address private _mediaContract;
    address public owner;
    string public baseURI = "";
    uint96 royaltyFeesInBips;
    address royaltyAddress;


    // Mapping from token ID to creator address
    mapping(uint256 => address) public _creators;
    mapping (uint256 => string) tokenURIs;

    constructor(
        string memory _name, 
        string memory _symbol,
        uint96 _royaltyFeesInBips,
        address _royaltyReciever
    ) ERC1155(_name, _symbol) {
        owner = msg.sender;
        bytes memory name_ = bytes(_name); // Uses memory
        bytes memory symbol_ = bytes(_symbol);
        require( name_.length != 0 && symbol_.length != 0, "ERC1155: Choose a name and symbol");
        _setDefaultRoyalty(_royaltyReciever, _royaltyFeesInBips);
    }

    modifier onlyOwner (){
        require(msg.sender == owner || msg.sender == _mediaContract, "Not the owner");
        _;
    }

    function configureMedia(address _mediaContractAddress) external onlyOwner{
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

    function _baseURI() internal view returns (string memory) {
        return baseURI;
    }

    function _name() internal view virtual returns (string memory) {
        return name;
    }

    function _symbol() internal view virtual returns (string memory) {
        return symbol;
    }

    function _setBaseURI(string memory _baseuri)  internal virtual {
        baseURI = _baseuri;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        tokenURIs[tokenId] = _tokenURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address _to, uint256 _id, uint256 _copies, string memory _tokenURI, uint96 _royalty)
        public onlyOwner returns(uint256, uint256) {
        _mint(_to, _id, _copies, "");
        setTokenURI(_id, _tokenURI);
        setTokenRoyaltyInfo(_id, _to, _royalty);
		_creators[_id] = _to;
        return(_id, _copies);
    }

    function transfer(address _owner, address _reciever, uint256 _tokenId, uint256 _copies) external returns (bool){
        safeTransferFrom(_owner, _reciever, _tokenId, _copies, "");
        return true;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setTokenRoyaltyInfo(uint256 _tokenId,address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _royaltyFeesInBips);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}