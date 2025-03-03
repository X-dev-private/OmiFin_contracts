// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleLiquidityPool is Ownable {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    // Swap fee as fraction (e.g., 3/1000 = 0.3%)
    uint256 public feeNumerator = 3;
    uint256 public feeDenominator = 1000;
    
    // Fee distribution to LPs (90%)
    uint256 public constant lpFeeNumerator = 9;
    uint256 public constant lpFeeDenominator = 10;

    uint256 public totalFeeA;
    uint256 public totalFeeB;

    mapping(address => uint256) public liquidityShares;
    uint256 public totalLiquidity;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event Swapped(address indexed user, address fromToken, address toToken, uint256 amountIn, uint256 amountOut);
    event SwapFeeUpdated(uint256 newNumerator, uint256 newDenominator);
    event FeesWithdrawn(address indexed provider, uint256 amountA, uint256 amountB);

    constructor(address _tokenA, address _tokenB, address initialOwner) Ownable(initialOwner) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 shares) {
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        if (totalLiquidity == 0) {
            shares = amountA + amountB;
        } else {
            shares = (amountA * totalLiquidity) / reserveA;
        }

        liquidityShares[msg.sender] += shares;
        totalLiquidity += shares;

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, shares);
    }

    function removeLiquidity(uint256 shares) external {
        require(shares > 0, "Share amount must be positive");
        require(liquidityShares[msg.sender] >= shares, "Insufficient shares");

        uint256 amountA = (shares * reserveA) / totalLiquidity;
        uint256 amountB = (shares * reserveB) / totalLiquidity;

        // Calculate 90% of accumulated fees proportional to shares
        uint256 feeShareA = (totalFeeA * shares * lpFeeNumerator) / (totalLiquidity * lpFeeDenominator);
        uint256 feeShareB = (totalFeeB * shares * lpFeeNumerator) / (totalLiquidity * lpFeeDenominator);

        liquidityShares[msg.sender] -= shares;
        totalLiquidity -= shares;

        reserveA -= amountA;
        reserveB -= amountB;

        totalFeeA -= feeShareA;
        totalFeeB -= feeShareB;

        tokenA.transfer(msg.sender, amountA + feeShareA);
        tokenB.transfer(msg.sender, amountB + feeShareB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, shares);
    }

    function withdrawFees() external {
        uint256 shares = liquidityShares[msg.sender];
        require(shares > 0, "No liquidity shares");

        uint256 feeShareA = (totalFeeA * shares * lpFeeNumerator) / (totalLiquidity * lpFeeDenominator);
        uint256 feeShareB = (totalFeeB * shares * lpFeeNumerator) / (totalLiquidity * lpFeeDenominator);
        
        require(feeShareA > 0 || feeShareB > 0, "No fees to withdraw");

        totalFeeA -= feeShareA;
        totalFeeB -= feeShareB;

        if(feeShareA > 0) tokenA.transfer(msg.sender, feeShareA);
        if(feeShareB > 0) tokenB.transfer(msg.sender, feeShareB);

        emit FeesWithdrawn(msg.sender, feeShareA, feeShareB);
    }

    function swap(address fromToken, uint256 amountIn) external returns (uint256 amountOut) {
        require(fromToken == address(tokenA) || fromToken == address(tokenB), "Invalid token");
        require(amountIn > 0, "Amount must be positive");

        bool isTokenA = fromToken == address(tokenA);
        IERC20 inputToken = isTokenA ? tokenA : tokenB;
        IERC20 outputToken = isTokenA ? tokenB : tokenA;

        uint256 reserveInput = isTokenA ? reserveA : reserveB;
        uint256 reserveOutput = isTokenA ? reserveB : reserveA;

        require(reserveInput > 0 && reserveOutput > 0, "Insufficient pool liquidity");

        inputToken.transferFrom(msg.sender, address(this), amountIn);

        uint256 fee = (amountIn * feeNumerator) / feeDenominator;
        uint256 amountInWithFee = amountIn - fee;

        if (isTokenA) {
            totalFeeA += (fee * lpFeeNumerator) / lpFeeDenominator;
        } else {
            totalFeeB += (fee * lpFeeNumerator) / lpFeeDenominator;
        }

        amountOut = (amountInWithFee * reserveOutput) / (reserveInput + amountInWithFee);
        require(amountOut > 0, "Insufficient output amount");

        outputToken.transfer(msg.sender, amountOut);

        if (isTokenA) {
            reserveA += amountInWithFee;
            reserveB -= amountOut;
        } else {
            reserveB += amountInWithFee;
            reserveA -= amountOut;
        }

        emit Swapped(msg.sender, fromToken, address(outputToken), amountIn, amountOut);
    }

    function setSwapFee(uint256 newNumerator, uint256 newDenominator) external onlyOwner {
        require(newDenominator > 0, "Denominator cannot be zero");
        require(newNumerator <= newDenominator, "Invalid fee ratio");
        require(newNumerator <= newDenominator / 10, "Maximum fee is 10%");
        
        feeNumerator = newNumerator;
        feeDenominator = newDenominator;
        emit SwapFeeUpdated(newNumerator, newDenominator);
    }
}