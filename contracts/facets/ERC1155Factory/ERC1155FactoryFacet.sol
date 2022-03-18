// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC1155/ERC1155Facet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./LibERC1155FactoryStorage.sol";

contract ERC1155Factory is ERC1155Facet, Ownable {

    modifier onlyMediaCaller() {
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        require(
            msg.sender == es._mediaContract,
            "ERC1155Factory: Unauthorized Access!"
        );
        _;
    }

    function configureMedia(address _mediaContractAddress) external onlyOwner {
        // TODO: Only Owner Modifier
        require(
            _mediaContractAddress != address(0),
            "ERC1155Factory: Invalid Media Contract Address!"
        );
        
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        
        require(
            es._mediaContract == address(0),
            "ERC1155Factory: Media Contract Alredy Configured!"
        );

        es._mediaContract = _mediaContractAddress;
    }

    function mint(
        uint256 _tokenID,
        address _owner,
        uint256 _totalSupply
    ) external onlyMediaCaller {
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();
        es.nftToOwners[_tokenID] = _owner;
        es.nftToCreators[_tokenID] = _owner;
        _mint(_owner, _tokenID, _totalSupply, "");
        setApprovalForAll(es._mediaContract, true);
    }

    /**
     * @notice This Method is used to Transfer Token
     * @dev This method is used while Direct Buy-Sell takes place
     *
     * @param _from Address of the Token Owner to transfer from
     * @param _to Address of the Token receiver
     * @param _tokenID TokenID of the Token to transfer
     * @param _amount Amount of Tokens to transfer, in case of Fungible Token transfer
     *
     * @return bool Transaction Status
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenID,
        uint256 _amount
    ) external onlyMediaCaller returns (bool) {
        require(_to != address(0x0), "ERC1155Factory: _to must be non-zero.");

        // require(
        //     _from == _msgSender() || _operatorApprovals[_from][_msgSender()] == true,
        //     'ERC1155Factory: Need operator approval for 3rd party transfers.'
        // );
        LibERC1155FactoryStorage.ERC1155FactoryStorage storage es = LibERC1155FactoryStorage.erc1155FactoryStorage();

        safeTransferFrom(_from, _to, _tokenID, _amount, "");
        setApprovalForAll(es._mediaContract, true);
        return true;
    }
}
