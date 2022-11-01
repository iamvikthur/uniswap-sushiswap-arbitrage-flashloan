// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.6;

import "hardhat/console.sol";

// Unisawp libraries and interface import
// librabies 
import "./libraries/UniswapV2Library.sol";
import "./libraries/SafeERC20.sol";

// interfaces
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./interfaces/IUniswapV2Router02.sol";


contract UniswapV2ShushiFlashSwap {
    using SafeERC20 for IERC20;

    // Factory and Router Addresses
    address private constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address private constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

    // Token Addresses 
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address private constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;

    // Trade Variables 
    uint256 private deadline = block.timestamp + 1 days;
    uint256 private MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    // FUND SMART CONTARCT
    // A function that allows smart contract to be funded 
    function fundFlashSwapContract(address _owner, address _token, uint256 _amount) public {
        IERC20(_token).transferFrom(_owner, address(this), _amount);
    }

    // GET CONTARCT BALANCE 
    // A function to get the balance of a token 
    function getBalanceOfToken(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    // PLACE A TRADE 
    // Executes placing a trade 
    function placeTrade(
        address _fromToken,
        address _toToken, 
        uint256 _amountIn, 
        address factory, 
        address router
    ) private returns (uint256) {
        address pair = IUniswapV2Factory(factory).getPair(_fromToken, _toToken);

        require(pair != address(0), "Pool does not exist");

        // Calculate Amount Out
        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 amountRequired = IUniswapV2Router01(router).getAmountsOut(_amountIn, path)[1];

        console.log("Amount Required: ", amountRequired);

        // Perform Arbitrage - Swap token for another token 
        uint256 amountReceived = IUniswapV2Router01(UNISWAP_ROUTER)
            .swapExactTokensForTokens(
                _amountIn, // amountIn
                amountRequired, // amountOutMin
                path, // path
                address(this), // address to
                deadline
            )[1];

        console.log("Amount Received: ", amountReceived);

        require(amountReceived > 0, "Aborted Tx:, Trade returned zero");

        return amountReceived;
    }

    // CHECK PROFITABILITY 
    // checks if the trade was profitable
    function checkProfitability(uint256 _input, uint256 _output) private pure returns(bool) {
        return _output > _input;
    }

    // INITIATE ARBITRAGE 
    // begins receiving loans to engage performing arbitrage trades 
    function startArbitrage(address _tokenBorrow, uint256 _amount) external {
        IERC20(USDC).safeApprove(UNISWAP_ROUTER, MAX_INT);
        IERC20(UNI).safeApprove(UNISWAP_ROUTER, MAX_INT);
        IERC20(LINK).safeApprove(UNISWAP_ROUTER, MAX_INT);

        IERC20(USDC).safeApprove(SUSHI_ROUTER, MAX_INT);
        IERC20(UNI).safeApprove(SUSHI_ROUTER, MAX_INT);
        IERC20(LINK).safeApprove(SUSHI_ROUTER, MAX_INT);

        // Get the Factory Pair address for combined tokens 
        address pair = IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenBorrow, WETH);

        // Return error is pai does not exist 
        require(pair != address(0), "UniswapV2Factory: Pair does not exist");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;

        // Passing data as byted so that the 'swap' function knows it is a flashload 
        bytes memory data = abi.encode(_tokenBorrow, _amount, msg.sender);


        // Execute the initial swap to get the loan 
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);

    }

    function uniswapV2Call(
        address _sender, 
        uint256 _amount0, 
        uint256 _amount1, 
        bytes calldata _data
    ) external {
        // Ensure request came from the contract 
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(UNISWAP_FACTORY).getPair(token0, token1);

        require(msg.sender == pair, "The function caller must match the pair");
        require(_sender == address(this), "Sender must match this contract");

        // Decode data for calculating the repayment 
        (address tokenBorrow, uint256 amount, address myAddress) = abi.decode(_data, (address, uint256, address));

        // Calculate the amount to repay at the end 
        uint256 fee = ((amount * 3) / 997 ) + 1;
        uint256 amountToRepay = amount + fee;

        // DO ARBITRAGE
        // !!!!!!!!!!!!!!!!!!!!!

        // Assign loan amount 
        uint256 loanAmount = _amount0 > 0 ? _amount0 : _amount1;

        // console.log("This is the loan amount", loanAmount);

        // place Trades
        uint256 trade1AcquiedCoin = placeTrade(USDC, LINK, loanAmount, UNISWAP_FACTORY, UNISWAP_ROUTER);
        console.log("trade1", trade1AcquiedCoin);
        uint256 trade2AcquiedCoin = placeTrade(LINK, USDC, trade1AcquiedCoin, SUSHI_FACTORY, SUSHI_ROUTER);
        console.log("trade2", trade2AcquiedCoin);


        // CHECK PROFITABILITY 
        // check if arbtrage was profitable
        bool profitCheck = checkProfitability(amountToRepay, trade2AcquiedCoin);
        console.log("Amount to repay", amountToRepay);
        require(profitCheck, "Arbirage was not profitable");


        // PAY YOURSELF 
        uint256 profit = trade2AcquiedCoin - amountToRepay;
        IERC20 otherToken = IERC20(USDC);
        otherToken.transfer(myAddress, profit);

        // Pay Loan Back 
        console.log("Amount to repay", amountToRepay);
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

}