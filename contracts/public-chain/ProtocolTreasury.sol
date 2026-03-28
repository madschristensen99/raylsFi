// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ProtocolTreasury is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    uint256 public totalCollected;
    
    event FeeCollected(uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed to, uint256 amount);

    constructor(address _asset) Ownable(msg.sender) {
        require(_asset != address(0), "Invalid asset address");
        asset = IERC20(_asset);
    }

    function collectFee(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        
        asset.safeTransferFrom(msg.sender, address(this), amount);
        totalCollected += amount;
        
        emit FeeCollected(amount, block.timestamp);
    }

    function getAccumulated() external view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be greater than 0");
        require(asset.balanceOf(address(this)) >= amount, "Insufficient balance");
        
        asset.safeTransfer(to, amount);
        
        emit Withdrawn(to, amount);
    }
}
