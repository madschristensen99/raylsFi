// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LendingPool is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct UserDeposit {
        uint256 principal;
        uint256 lastUpdateTime;
        uint256 accruedInterest;
    }

    struct BorrowPosition {
        uint256 borrowed;
        uint256 collateral;
        uint256 lastUpdateTime;
        uint256 accruedInterest;
    }

    IERC20 public immutable asset;
    
    uint256 public totalDeposits;
    uint256 public totalBorrowed;
    uint256 public baseInterestRate = 200;
    uint256 public utilizationMultiplier = 1000;
    uint256 public constant RATE_PRECISION = 10000;
    uint256 public constant SECONDS_PER_YEAR = 365 days;
    
    mapping(address => UserDeposit) public deposits;
    mapping(address => BorrowPosition) public borrows;
    
    event Supplied(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount, uint256 interest);
    event Borrowed(address indexed user, uint256 amount, uint256 collateral);
    event Repaid(address indexed user, uint256 amount, uint256 interest);
    event InterestRateUpdated(uint256 baseRate, uint256 multiplier);

    constructor(address _asset) Ownable(msg.sender) {
        require(_asset != address(0), "Invalid asset address");
        asset = IERC20(_asset);
    }

    function supply(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        _updateInterest(msg.sender);
        
        asset.safeTransferFrom(msg.sender, address(this), amount);
        
        deposits[msg.sender].principal += amount;
        deposits[msg.sender].lastUpdateTime = block.timestamp;
        totalDeposits += amount;
        
        emit Supplied(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        _updateInterest(msg.sender);
        
        UserDeposit storage deposit = deposits[msg.sender];
        uint256 totalAvailable = deposit.principal + deposit.accruedInterest;
        require(totalAvailable >= amount, "Insufficient balance");
        
        uint256 availableLiquidity = asset.balanceOf(address(this));
        require(availableLiquidity >= amount, "Insufficient liquidity");
        
        uint256 interest = 0;
        if (amount <= deposit.accruedInterest) {
            deposit.accruedInterest -= amount;
            interest = amount;
        } else {
            uint256 principalToWithdraw = amount - deposit.accruedInterest;
            interest = deposit.accruedInterest;
            deposit.accruedInterest = 0;
            deposit.principal -= principalToWithdraw;
            totalDeposits -= principalToWithdraw;
        }
        
        asset.safeTransfer(msg.sender, amount);
        
        emit Withdrawn(msg.sender, amount, interest);
    }

    function borrow(uint256 amount, uint256 collateralAmount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(collateralAmount >= amount * 150 / 100, "Insufficient collateral (need 150%)");
        
        _updateBorrowInterest(msg.sender);
        
        asset.safeTransferFrom(msg.sender, address(this), collateralAmount);
        
        borrows[msg.sender].borrowed += amount;
        borrows[msg.sender].collateral += collateralAmount;
        borrows[msg.sender].lastUpdateTime = block.timestamp;
        totalBorrowed += amount;
        
        require(asset.balanceOf(address(this)) >= amount, "Insufficient liquidity");
        asset.safeTransfer(msg.sender, amount);
        
        emit Borrowed(msg.sender, amount, collateralAmount);
    }

    function repay(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        _updateBorrowInterest(msg.sender);
        
        BorrowPosition storage position = borrows[msg.sender];
        uint256 totalOwed = position.borrowed + position.accruedInterest;
        require(totalOwed > 0, "No active borrow");
        require(amount <= totalOwed, "Amount exceeds debt");
        
        asset.safeTransferFrom(msg.sender, address(this), amount);
        
        uint256 interest = 0;
        if (amount <= position.accruedInterest) {
            position.accruedInterest -= amount;
            interest = amount;
        } else {
            uint256 principalRepayment = amount - position.accruedInterest;
            interest = position.accruedInterest;
            position.accruedInterest = 0;
            position.borrowed -= principalRepayment;
            totalBorrowed -= principalRepayment;
        }
        
        if (position.borrowed == 0 && position.accruedInterest == 0) {
            uint256 collateralToReturn = position.collateral;
            position.collateral = 0;
            asset.safeTransfer(msg.sender, collateralToReturn);
        }
        
        emit Repaid(msg.sender, amount, interest);
    }

    function getCurrentAPY() public view returns (uint256) {
        if (totalDeposits == 0) return baseInterestRate;
        
        uint256 utilization = (totalBorrowed * RATE_PRECISION) / totalDeposits;
        uint256 borrowRate = baseInterestRate + (utilization * utilizationMultiplier / RATE_PRECISION);
        uint256 supplyRate = (borrowRate * utilization) / RATE_PRECISION;
        
        return supplyRate;
    }

    function getUserBalance(address user) external view returns (uint256 principal, uint256 interest, uint256 total) {
        UserDeposit memory deposit = deposits[user];
        principal = deposit.principal;
        
        if (deposit.principal > 0 && deposit.lastUpdateTime > 0) {
            uint256 timeElapsed = block.timestamp - deposit.lastUpdateTime;
            uint256 rate = getCurrentAPY();
            uint256 newInterest = (deposit.principal * rate * timeElapsed) / (RATE_PRECISION * SECONDS_PER_YEAR);
            interest = deposit.accruedInterest + newInterest;
        } else {
            interest = deposit.accruedInterest;
        }
        
        total = principal + interest;
    }

    function _updateInterest(address user) internal {
        UserDeposit storage deposit = deposits[user];
        
        if (deposit.principal > 0 && deposit.lastUpdateTime > 0) {
            uint256 timeElapsed = block.timestamp - deposit.lastUpdateTime;
            uint256 rate = getCurrentAPY();
            uint256 interest = (deposit.principal * rate * timeElapsed) / (RATE_PRECISION * SECONDS_PER_YEAR);
            deposit.accruedInterest += interest;
        }
        
        deposit.lastUpdateTime = block.timestamp;
    }

    function _updateBorrowInterest(address user) internal {
        BorrowPosition storage position = borrows[user];
        
        if (position.borrowed > 0 && position.lastUpdateTime > 0) {
            uint256 timeElapsed = block.timestamp - position.lastUpdateTime;
            uint256 borrowRate = baseInterestRate + utilizationMultiplier;
            uint256 interest = (position.borrowed * borrowRate * timeElapsed) / (RATE_PRECISION * SECONDS_PER_YEAR);
            position.accruedInterest += interest;
        }
        
        position.lastUpdateTime = block.timestamp;
    }

    function setInterestRates(uint256 _baseRate, uint256 _multiplier) external onlyOwner {
        baseInterestRate = _baseRate;
        utilizationMultiplier = _multiplier;
        emit InterestRateUpdated(_baseRate, _multiplier);
    }
}
