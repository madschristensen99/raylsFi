// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PrivacyGovernor is Ownable {
    enum DisclosureLevel {
        NONE,
        EXISTENCE_ONLY,
        PARTIAL,
        FULL
    }

    struct DisclosureRequest {
        bytes32 assetId;
        DisclosureLevel level;
        address requester;
        bool approved;
        uint256 timestamp;
    }

    mapping(bytes32 => DisclosureLevel) public assetDisclosures;
    mapping(bytes32 => DisclosureRequest) public disclosureRequests;
    
    event DisclosureRequested(bytes32 indexed assetId, DisclosureLevel level, address requester);
    event DisclosureApproved(bytes32 indexed assetId, DisclosureLevel level);
    event DisclosureRevoked(bytes32 indexed assetId);

    constructor() Ownable(msg.sender) {}

    function requestDisclosure(bytes32 assetId, DisclosureLevel level) external {
        require(assetId != bytes32(0), "Invalid asset ID");
        
        disclosureRequests[assetId] = DisclosureRequest({
            assetId: assetId,
            level: level,
            requester: msg.sender,
            approved: false,
            timestamp: block.timestamp
        });
        
        emit DisclosureRequested(assetId, level, msg.sender);
    }

    function approveDisclosure(bytes32 assetId, DisclosureLevel level) external onlyOwner {
        require(assetId != bytes32(0), "Invalid asset ID");
        
        assetDisclosures[assetId] = level;
        
        if (disclosureRequests[assetId].assetId == assetId) {
            disclosureRequests[assetId].approved = true;
        }
        
        emit DisclosureApproved(assetId, level);
    }

    function revokeDisclosure(bytes32 assetId) external onlyOwner {
        require(assetId != bytes32(0), "Invalid asset ID");
        
        assetDisclosures[assetId] = DisclosureLevel.NONE;
        emit DisclosureRevoked(assetId);
    }

    function getDisclosureLevel(bytes32 assetId) external view returns (DisclosureLevel) {
        return assetDisclosures[assetId];
    }

    function getDisclosureRequest(bytes32 assetId) external view returns (DisclosureRequest memory) {
        return disclosureRequests[assetId];
    }
}
