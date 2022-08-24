// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */

contract ERC2981 is ERC165 {

    struct RoyaltyInfo {
        address[] receiver;
        uint96[] royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    uint256[] private royaltyAmount;

    function initializeRoyaltyAmount() internal {
        delete royaltyAmount;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public virtual returns (address[] memory , uint256[] memory) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];
        if (royalty.receiver[0] == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }
        
        initializeRoyaltyAmount(); // 
        for(uint i=0; i < royalty.royaltyFraction.length; i++){
            royaltyAmount.push((_salePrice * royalty.royaltyFraction[i]) / _feeDenominator());
            // royaltyAmount.push(5);
        }
    
        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
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
    function _setDefaultRoyalty(address[] memory receiver, uint96[] memory feeNumerator) internal {
        // At least one royaltyReceiver is required.
        require(receiver.length > 0, "No Royalty details provided");
        // Check on the maximum size over which the for loop will run over.
        require(receiver.length <= 5, "Too many royalty recievers details");
        //Check the length of receiver and fees should match
        require(receiver.length == feeNumerator.length, "Mismatch of Royalty recievers and their fees");
        uint totalFeeNumerator=0;
        for(uint i=0 ; i < feeNumerator.length; i++){
            totalFeeNumerator += feeNumerator[i];
        }
        require(totalFeeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        uint96[] memory feeFractions;
        address[] memory participants;
        participants=receiver;
        feeFractions = feeNumerator;  
        _defaultRoyaltyInfo = RoyaltyInfo(participants, feeFractions); 
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address[] memory receiver,
        uint96[] memory feeNumerator
    ) internal {
        // At least one royaltyReceiver is required.
        require(receiver.length > 0, "No Royalty details provided");
        // Check on the maximum size over which the for loop will run over.
        require(receiver.length <= 5, "Too many royalty recievers details");
        //Check the length of receiver and fees should match
        require(receiver.length == feeNumerator.length, "Mismatch of Royalty recievers and their fees");
        uint totalFeeNumerator=0;
        for(uint i=0 ; i < feeNumerator.length; i++){
            totalFeeNumerator += feeNumerator[i];
        }
        require(totalFeeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        uint96[] memory feeFractions;
        address[] memory participants;
        participants=receiver;
        feeFractions = feeNumerator;  
        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(participants, feeFractions);
        // return(_tokenRoyaltyInfo[tokenId]);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}