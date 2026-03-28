// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ShareToken is ERC20, Ownable {
    bytes32 public attestationHash;
    string public assetMetadata;
    
    event Minted(address indexed to, uint256 amount, bytes32 attestationHash);
    event Burned(address indexed from, uint256 amount);
    event AttestationUpdated(bytes32 newHash, string metadata);

    constructor(
        string memory name,
        string memory symbol,
        bytes32 _attestationHash,
        string memory _metadata
    ) ERC20(name, symbol) Ownable(msg.sender) {
        attestationHash = _attestationHash;
        assetMetadata = _metadata;
    }

    function mint(address to, uint256 amount, bytes32 _attestationHash) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        
        if (_attestationHash != bytes32(0)) {
            attestationHash = _attestationHash;
        }
        
        _mint(to, amount);
        
        emit Minted(to, amount, attestationHash);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        require(from != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");
        
        _burn(from, amount);
        
        emit Burned(from, amount);
    }

    function updateAttestation(bytes32 newHash, string memory metadata) external onlyOwner {
        attestationHash = newHash;
        assetMetadata = metadata;
        
        emit AttestationUpdated(newHash, metadata);
    }
}
