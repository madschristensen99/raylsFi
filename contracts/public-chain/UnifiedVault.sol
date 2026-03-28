// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UnifiedVault is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    address public yieldRouter;
    IERC20 public immutable asset;
    
    mapping(address => uint256) public userDeposits;
    mapping(address => uint256) public userYield;
    
    uint256 public totalDeposited;
    uint256 public totalYieldAccrued;
    
    event BridgedReceived(address indexed user, uint256 amount, uint256 timestamp);
    event WithdrawnToPrivacy(address indexed user, uint256 amount, uint256 timestamp);
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 timestamp);
    event YieldRouterUpdated(address indexed newRouter);
    event YieldDistributed(address indexed user, uint256 amount);

    constructor(address _asset) Ownable(msg.sender) {
        require(_asset != address(0), "Invalid asset address");
        asset = IERC20(_asset);
    }

    function setYieldRouter(address _yieldRouter) external onlyOwner {
        require(_yieldRouter != address(0), "Invalid router address");
        yieldRouter = _yieldRouter;
        emit YieldRouterUpdated(_yieldRouter);
    }

    function receiveBridged(address user, uint256 amount) external onlyOwner nonReentrant {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        
        userDeposits[user] += amount;
        totalDeposited += amount;
        
        emit BridgedReceived(user, amount, block.timestamp);
        
        if (yieldRouter != address(0)) {
            asset.forceApprove(yieldRouter, amount);
        }
    }

    function withdrawToPrivacy(address user, uint256 amount) external onlyOwner nonReentrant {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(userDeposits[user] >= amount, "Insufficient user deposit");
        
        userDeposits[user] -= amount;
        totalDeposited -= amount;
        
        emit WithdrawnToPrivacy(user, amount, block.timestamp);
    }

    function emergencyWithdraw(address user, uint256 amount) external onlyOwner nonReentrant {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(userDeposits[user] >= amount, "Insufficient user deposit");
        
        userDeposits[user] -= amount;
        totalDeposited -= amount;
        
        asset.safeTransfer(user, amount);
        
        emit EmergencyWithdraw(user, amount, block.timestamp);
    }

    function distributeYield(address user, uint256 amount) external {
        require(msg.sender == yieldRouter || msg.sender == owner(), "Unauthorized");
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        
        userYield[user] += amount;
        totalYieldAccrued += amount;
        
        emit YieldDistributed(user, amount);
    }

    function getUserBalance(address user) external view returns (uint256 deposits, uint256 yield, uint256 total) {
        deposits = userDeposits[user];
        yield = userYield[user];
        total = deposits + yield;
    }

    function getTotalValue() external view returns (uint256) {
        return totalDeposited + totalYieldAccrued;
    }
}
