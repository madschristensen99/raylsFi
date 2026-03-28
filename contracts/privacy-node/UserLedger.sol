// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract UserLedger is Ownable, ReentrancyGuard {
    struct Position {
        bytes32 assetId;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => uint256) private balances;
    mapping(address => Position[]) private positions;
    mapping(address => bytes32[]) private paymentHistory;
    
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Debit(address indexed user, uint256 amount, uint256 timestamp);
    event PaymentRecorded(address indexed user, uint256 amount, bytes32 merchantHash, uint256 timestamp);
    event PositionAdded(address indexed user, bytes32 assetId, uint256 amount);
    event BridgeInitiated(address indexed user, uint256 amount, uint256 timestamp);

    constructor() Ownable(msg.sender) {}

    function deposit(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        
        balances[user] += amount;
        emit Deposit(user, amount, block.timestamp);
    }

    function debit(address user, uint256 amount) external onlyOwner nonReentrant {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[user] >= amount, "Insufficient balance");
        
        balances[user] -= amount;
        emit Debit(user, amount, block.timestamp);
    }

    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    function recordPayment(address user, uint256 amount, bytes32 merchantHash) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        
        paymentHistory[user].push(merchantHash);
        emit PaymentRecorded(user, amount, merchantHash, block.timestamp);
    }

    function addPosition(address user, bytes32 assetId, uint256 amount) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        
        positions[user].push(Position({
            assetId: assetId,
            amount: amount,
            timestamp: block.timestamp
        }));
        
        emit PositionAdded(user, assetId, amount);
    }

    function getPositions(address user) external view returns (Position[] memory) {
        return positions[user];
    }

    function getPaymentCount(address user) external view returns (uint256) {
        return paymentHistory[user].length;
    }

    function initiateBridge(address user, uint256 amount) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be greater than 0");
        require(balances[user] >= amount, "Insufficient balance");
        
        balances[user] -= amount;
        emit BridgeInitiated(user, amount, block.timestamp);
    }
}
