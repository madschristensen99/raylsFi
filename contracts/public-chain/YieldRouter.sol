// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LendingPool.sol";
import "./UnifiedVault.sol";
import "./ProtocolTreasury.sol";

contract YieldRouter is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    LendingPool public lendingPool;
    UnifiedVault public vault;
    ProtocolTreasury public treasury;
    
    uint256 public platformFeeBps = 2300;
    uint256 public constant BPS_DENOMINATOR = 10000;
    
    mapping(address => uint256) public userPrincipal;
    mapping(address => uint256) public lastHarvestTime;
    
    event Deposited(address indexed user, uint256 amount, address indexed protocol);
    event Withdrawn(address indexed user, uint256 amount, address indexed protocol);
    event Harvested(uint256 totalYield, uint256 platformFee, uint256 userYield);
    event PlatformFeeUpdated(uint256 newFeeBps);

    constructor(
        address _asset,
        address _lendingPool,
        address _vault,
        address _treasury
    ) Ownable(msg.sender) {
        require(_asset != address(0), "Invalid asset");
        require(_lendingPool != address(0), "Invalid lending pool");
        require(_vault != address(0), "Invalid vault");
        require(_treasury != address(0), "Invalid treasury");
        
        asset = IERC20(_asset);
        lendingPool = LendingPool(_lendingPool);
        vault = UnifiedVault(_vault);
        treasury = ProtocolTreasury(_treasury);
    }

    function deposit(uint256 amount, address user) external nonReentrant {
        require(msg.sender == address(vault) || msg.sender == owner(), "Unauthorized");
        require(amount > 0, "Amount must be greater than 0");
        require(user != address(0), "Invalid user");
        
        asset.safeTransferFrom(msg.sender, address(this), amount);
        
        asset.forceApprove(address(lendingPool), amount);
        lendingPool.supply(amount);
        
        userPrincipal[user] += amount;
        lastHarvestTime[user] = block.timestamp;
        
        emit Deposited(user, amount, address(lendingPool));
    }

    function withdraw(uint256 amount, address user) external nonReentrant {
        require(msg.sender == address(vault) || msg.sender == owner(), "Unauthorized");
        require(amount > 0, "Amount must be greater than 0");
        require(userPrincipal[user] >= amount, "Insufficient principal");
        
        lendingPool.withdraw(amount);
        
        userPrincipal[user] -= amount;
        
        asset.safeTransfer(address(vault), amount);
        
        emit Withdrawn(user, amount, address(lendingPool));
    }

    function harvest() external nonReentrant returns (uint256 platformFee, uint256 userYield) {
        (uint256 principal, uint256 interest, ) = lendingPool.getUserBalance(address(this));
        
        require(interest > 0, "No yield to harvest");
        
        lendingPool.withdraw(interest);
        
        platformFee = (interest * platformFeeBps) / BPS_DENOMINATOR;
        userYield = interest - platformFee;
        
        if (platformFee > 0) {
            asset.forceApprove(address(treasury), platformFee);
            treasury.collectFee(platformFee);
        }
        
        emit Harvested(interest, platformFee, userYield);
        
        return (platformFee, userYield);
    }

    function getYieldRate() external view returns (uint256) {
        return lendingPool.getCurrentAPY();
    }

    function getUserYield(address user) external view returns (uint256) {
        if (userPrincipal[user] == 0) return 0;
        
        (uint256 totalPrincipal, uint256 totalInterest, ) = lendingPool.getUserBalance(address(this));
        
        if (totalPrincipal == 0) return 0;
        
        uint256 userShare = (userPrincipal[user] * totalInterest) / totalPrincipal;
        uint256 userNet = userShare - (userShare * platformFeeBps / BPS_DENOMINATOR);
        
        return userNet;
    }

    function setPlatformFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 5000, "Fee too high (max 50%)");
        platformFeeBps = newFeeBps;
        emit PlatformFeeUpdated(newFeeBps);
    }

    function getTotalDeposited() external view returns (uint256) {
        (uint256 principal, , ) = lendingPool.getUserBalance(address(this));
        return principal;
    }
}
