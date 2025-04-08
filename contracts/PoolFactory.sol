// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolFactory is Ownable {
    event PoolCreated(
        address indexed poolAddress,
        address indexed tokenA,
        address indexed tokenB,
        address creator
    );

    mapping(address => address[]) public ownerPools;
    address[] public allPools;
    // Mapeamento de token para pools que o contêm
    mapping(address => address[]) public tokenToPools;

    constructor() Ownable(msg.sender) {}

    function createPool(
        address tokenA,
        address tokenB
    ) external returns (address) {
        require(tokenA != tokenB, "Tokens must be different");
        require(tokenA != address(0) && tokenB != address(0), "Invalid token address");

        SimpleLiquidityPool newPool = new SimpleLiquidityPool(tokenA, tokenB, msg.sender);
        address poolAddress = address(newPool);

        ownerPools[msg.sender].push(poolAddress);
        allPools.push(poolAddress);
        
        // Adiciona o pool aos mapeamentos de ambos os tokens
        tokenToPools[tokenA].push(poolAddress);
        tokenToPools[tokenB].push(poolAddress);

        emit PoolCreated(poolAddress, tokenA, tokenB, msg.sender);
        return poolAddress;
    }

    // Nova função que retorna todos os endereços de pools criados
    function getAllPools() external view returns (address[] memory) {
        return allPools;
    }

    // Nova função que retorna todos os dados de uma pool específica
    function getPoolData(address poolAddress) external view returns (
        address tokenA,
        address tokenB,
        uint256 reserveA,
        uint256 reserveB,
        uint256 feeNumerator,
        uint256 feeDenominator,
        uint256 totalLiquidity,
        address poolOwner
    ) {
        SimpleLiquidityPool pool = SimpleLiquidityPool(poolAddress);
        return (
            address(pool.tokenA()),
            address(pool.tokenB()),
            pool.reserveA(),
            pool.reserveB(),
            pool.feeNumerator(),
            pool.feeDenominator(),
            pool.totalLiquidity(),
            pool.owner()
        );
    }

    function getPoolsByOwner(address owner) external view returns (address[] memory) {
        return ownerPools[owner];
    }

    // Função para buscar pools que contêm um token específico
    function getPoolsByToken(address token) external view returns (address[] memory) {
        return tokenToPools[token];
    }

    function getAllPoolPairs() external view returns (address[2][] memory) {
        address[2][] memory pairs = new address[2][](allPools.length);

        for (uint256 i = 0; i < allPools.length; i++) {
            SimpleLiquidityPool pool = SimpleLiquidityPool(allPools[i]);
            pairs[i] = [address(pool.tokenA()), address(pool.tokenB())];
        }

        return pairs;
    }

    function getTotalPools() external view returns (uint256) {
        return allPools.length;
    }
}

contract SimpleLiquidityPool is Ownable {
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    // Swap fee as fraction (e.g., 3/1000 = 0.3%)
    uint256 public feeNumerator = 3;
    uint256 public constant feeDenominator = 1000;

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

    function getPoolData() external view returns (
        address tokenAAddress,
        address tokenBAddress,
        uint256 tokenAReserve,
        uint256 tokenBReserve,
        uint256 currentFeeNumerator,
        uint256 currentFeeDenominator,
        uint256 poolTotalLiquidity
    ) {
        return (
            address(tokenA),
            address(tokenB),
            reserveA,
            reserveB,
            feeNumerator,
            feeDenominator,
            totalLiquidity
        );
    }

    function getUserDepositedTokens(address user) external view returns (uint256 amountA, uint256 amountB) {
        uint256 shares = liquidityShares[user];
        if (shares == 0 || totalLiquidity == 0) {
            return (0, 0);
        }
        
        amountA = (shares * reserveA) / totalLiquidity;
        amountB = (shares * reserveB) / totalLiquidity;
    }

    function getAvailableFees(address user) external view returns (uint256 amountA, uint256 amountB) {
        uint256 shares = liquidityShares[user];
        if (shares == 0 || totalLiquidity == 0) {
            return (0, 0);
        }
        
        amountA = (totalFeeA * shares) / totalLiquidity;
        amountB = (totalFeeB * shares) / totalLiquidity;
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

        // Calculate accumulated fees proportional to shares (100% agora)
        uint256 feeShareA = (totalFeeA * shares) / totalLiquidity;
        uint256 feeShareB = (totalFeeB * shares) / totalLiquidity;

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

        uint256 feeShareA = (totalFeeA * shares) / totalLiquidity;
        uint256 feeShareB = (totalFeeB * shares) / totalLiquidity;
        
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

        // Toda a taxa vai para os LPs agora (100%)
        if (isTokenA) {
            totalFeeA += fee;
        } else {
            totalFeeB += fee;
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

    function setSwapFee(uint256 newNumerator) external onlyOwner {
        require(newNumerator <= feeDenominator / 10, "Maximum fee is 10%"); // 100/1000 = 10%
        require(newNumerator > 0, "Fee cannot be zero");
        
        feeNumerator = newNumerator;
        emit SwapFeeUpdated(newNumerator, feeDenominator);
    }
}
