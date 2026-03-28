// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AIAttestation is Ownable {
    using ECDSA for bytes32;

    struct Attestation {
        bytes32 assetId;
        bytes signature;
        string metadata;
        uint256 timestamp;
        address attester;
        bool verified;
    }

    mapping(bytes32 => Attestation) public attestations;
    mapping(address => bool) public authorizedAttesters;
    
    event AttestationPosted(bytes32 indexed assetId, address indexed attester, uint256 timestamp);
    event AttesterAuthorized(address indexed attester);
    event AttesterRevoked(address indexed attester);

    constructor() Ownable(msg.sender) {
        authorizedAttesters[msg.sender] = true;
    }

    function authorizeAttester(address attester) external onlyOwner {
        require(attester != address(0), "Invalid attester address");
        authorizedAttesters[attester] = true;
        emit AttesterAuthorized(attester);
    }

    function revokeAttester(address attester) external onlyOwner {
        authorizedAttesters[attester] = false;
        emit AttesterRevoked(attester);
    }

    function postAttestation(
        bytes32 assetId,
        bytes memory signature,
        string memory metadata
    ) external {
        require(authorizedAttesters[msg.sender], "Unauthorized attester");
        require(assetId != bytes32(0), "Invalid asset ID");
        
        attestations[assetId] = Attestation({
            assetId: assetId,
            signature: signature,
            metadata: metadata,
            timestamp: block.timestamp,
            attester: msg.sender,
            verified: true
        });
        
        emit AttestationPosted(assetId, msg.sender, block.timestamp);
    }

    function verifyAttestation(bytes32 assetId) external view returns (bool) {
        return attestations[assetId].verified && attestations[assetId].timestamp > 0;
    }

    function getAttestation(bytes32 assetId) external view returns (Attestation memory) {
        return attestations[assetId];
    }
}
