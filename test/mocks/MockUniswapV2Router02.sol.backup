// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../src/interfaces/IUniswapV2Router02.sol";
import "../../src/interfaces/IUniswapV2Factory.sol";
import "./MockUniswapV2Pair.sol";

/**
 * @title MockUniswapV2Router02
 * @dev Simplified mock of Uniswap V2 Router for testing
 */
contract MockUniswapV2Router02 is IUniswapV2Router02 {
    address private immutable _factory;
    address private immutable _WETH;

    constructor(address factory_, address WETH_) {
        _factory = factory_;
        _WETH = WETH_;
    }

    function factory() external view override returns (address) {
        return _factory;
    }

    function WETH() external view override returns (address) {
        return _WETH;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        address pair = IUniswapV2Factory(_factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            pair = IUniswapV2Factory(_factory).createPair(tokenA, tokenB);
        }

        amountA = amountADesired;
        amountB = amountBDesired;

        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");

        IERC20(tokenA).transferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountB);

        liquidity = MockUniswapV2Pair(pair).mint(to);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint
    ) external returns (uint amountA, uint amountB) {
        address pair = IUniswapV2Factory(_factory).getPair(tokenA, tokenB);
        require(pair != address(0), "PAIR_NOT_EXISTS");

        IERC20(pair).transferFrom(msg.sender, pair, liquidity);
        (uint amount0, uint amount1) = MockUniswapV2Pair(pair).burn(to);

        (address token0,) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);

        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");
    }

    function swapExactTokensForTokens(
        uint,
        uint,
        address[] calldata,
        address,
        uint
    ) external pure returns (uint[] memory amounts) {
        amounts = new uint[](2);
        return amounts;
    }

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB) {
        require(amountA > 0, "INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    function getAmountOut(uint, uint, uint) external pure returns (uint) {
        return 0;
    }

    function getAmountIn(uint, uint, uint) external pure returns (uint) {
        return 0;
    }

    function getAmountsOut(uint, address[] calldata path) external pure returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        return amounts;
    }

    function getAmountsIn(uint, address[] calldata path) external pure returns (uint[] memory amounts) {
        amounts = new uint[](path.length);
        return amounts;
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
    }
}
