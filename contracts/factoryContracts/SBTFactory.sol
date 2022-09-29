// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.6;

// - ability to mint one or n number of SBTs at once
// - ability to have a whitelist of wallets who can mint SBTs from a given collection
// - as SBT creator (project) I should be able to deploy collection contract and whitelist who can mint from it (IERC4671 and IERC4671Delegate)
// - ability to update metadata associated with SBT collection and tokens
// - SBTs should forever exist even if contract owner project dies
// - SBT collection owner and token owner themselves should be able to burn their SBT (https://eips.ethereum.org/EIPS/eip-5484)
// - SBTs should adhere to these standards to cover current and future use cases: https://github.com/rugpullindex/awesome-soulbound-tokens/blob/main/README.md

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IERC4973.sol";
import "../ERC4973.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IERC5484.sol";

contract SBTFactory is ERC4973, IERC5484 {
    address public creator;
    uint256 public maxMintLimit = 5;

    struct UserInfo {
        address user; // address of user role
        uint256 expires; // unix timestamp, user expires
    }

    mapping(uint256 => UserInfo) internal _users;
    mapping(uint256 => BurnAuth) internal _auth;
    mapping(uint256 => string) private token_Uri;

    uint256 mapSize = 0; //Keeps a count of white listed users. Max is 2000
    bool public whitelistEnabled = false;
    mapping(address => bool) public whitelist;

    constructor(string memory name_, string memory symbol_) ERC4973(name_, symbol_) {
        creator = msg.sender;
    }

    using Counters for Counters.Counter;
    Counters.Counter private tokenIdCounter;

    mapping(uint256 => address) nftToOwners;

    modifier onlyCreator() {
        require(msg.sender == creator, "Not the owner");
        _;
    }

    function burnAuth(uint256 tokenId) external view returns (BurnAuth) {
        return _auth[tokenId];
    }

    function setURI(uint256 tokenId, string memory newuri) public {
        require(_exists(tokenId), "tokenURI: token doesn't exist");
        if (whitelistEnabled == false) {
            require(msg.sender == creator, "Address not whitelisted");
        }
        if (whitelistEnabled == true) {
            require(whitelist[msg.sender], "Address not whitelisted");
        }
        token_Uri[tokenId] = newuri;
    }

    function issueOne(
        address _recipient,
        string memory _uri,
        uint256 _expires
    ) external {
        if (whitelistEnabled == false) {
            require(msg.sender == creator, "Address not whitelisted");
        }
        if (whitelistEnabled == true) {
            require(whitelist[msg.sender], "Address not whitelisted");
        }
        uint256 id = tokenIdCounter.current();
        tokenIdCounter.increment();

        _mint(_recipient, id, _uri);
        setURI(id, _uri);
        _auth[id] = BurnAuth.Both;
        nftToOwners[id] = _recipient;
        _setUser(id, _recipient, _expires);

        emit Issued(msg.sender, _recipient, id, _auth[id]);
    }

    function issueMany(
        address[] memory _recipient,
        string[] memory _uri,
        uint256[] memory _expires
    ) external {
        require(_recipient.length <= maxMintLimit, "SBT: Number of reciepient exceed the max mint limit");
        require(_recipient.length == _uri.length && _recipient.length == _expires.length, "SBT: Mismatch of recipientsor URI or exp Date");
        //require
        if (whitelistEnabled == false) {
            require(msg.sender == creator, "Address not whitelisted");
        }
        if (whitelistEnabled == true) {
            require(whitelist[msg.sender], "Address not whitelisted");
        }

        for (uint256 i = 0; i < _recipient.length; i++) {
            uint256 id = tokenIdCounter.current();
            tokenIdCounter.increment();

            _mint(_recipient[i], id, _uri[i]);

            _auth[id] = BurnAuth.Both;
            nftToOwners[id] = _recipient[i];
            _setUser(id, _recipient[i], _expires[i]);
            emit Issued(msg.sender, _recipient[i], id, _auth[id]);
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "tokenURI: token doesn't exist");
        return token_Uri[tokenId];
    }

    function _setUser(
        uint256 tokenId,
        address user,
        uint256 expires
    ) internal {
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
        // emit UpdateUser(tokenId, user, expires);
    }

    function getExpDate(uint256 _tokenId) public view returns (uint256 _expDate, address _user) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 expDate = _users[_tokenId].expires;
        address userAddress = _users[_tokenId].user;
        return (expDate, userAddress);
    }

    function extend(uint256 newExpiration, uint256 _tokenId) external {
        require(msg.sender == creator, " not an creator");
        require(newExpiration > block.timestamp, " Not valid time");
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        _users[_tokenId].expires = newExpiration;
    }

    function setWhitelistEnabled(bool _state) public onlyCreator {
        whitelistEnabled = _state;
    }

    function setWhitelist(address[] calldata newAddresses) public onlyCreator {
        // At least one royaltyReceiver is required.
        require(newAddresses.length > 0, "No user details provided");
        // Check on the maximum size over which the for loop will run over.
        require(newAddresses.length < 2000, "Too many userss to whitelist");
        for (uint256 i = 0; i < newAddresses.length; i++) {
            require(mapSize < 2000, "Maximum Users already whitelisted");
            whitelist[newAddresses[i]] = true;
            mapSize++;
        }
    }

    function removeWhitelist(address[] calldata currentAddresses) public onlyCreator {
        // At least one royaltyReceiver is required.
        require(currentAddresses.length > 0, "No user details provided");
        // Check on the maximum size over which the for loop will run over.
        require(currentAddresses.length <= 5, "Too many userss to whitelist");
        for (uint256 i = 0; i < currentAddresses.length; i++) {
            delete whitelist[currentAddresses[i]];
            mapSize--;
        }
    }

    ///@dev change how many NFTs can be minted at a time
    function setMaxMintLimit(uint256 _newMaxMintLimit) public onlyCreator {
        maxMintLimit = _newMaxMintLimit;
    }

    function burn(uint256 tokenId) public override {
        if (_auth[tokenId] == BurnAuth.IssuerOnly) {
            require(msg.sender == creator, "Not Authorised");
        }
        if (_auth[tokenId] == BurnAuth.OwnerOnly) {
            require(msg.sender == nftToOwners[tokenId], "Not Authorised");
        }
        if (_auth[tokenId] == BurnAuth.Both) {
            require(msg.sender == creator || msg.sender == nftToOwners[tokenId], "Not Authorised");
        }

        _burn(tokenId);
        delete _auth[tokenId];
        delete _users[tokenId];
        delete nftToOwners[tokenId];
    }
}
