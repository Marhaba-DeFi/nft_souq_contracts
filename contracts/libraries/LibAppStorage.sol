// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AppStorage {
    address _mediaContract; 
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
}