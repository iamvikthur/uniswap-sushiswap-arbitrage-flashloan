const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { impersonateFundErc20 } = require("../utils/utilities");
const { abi } = require("../artifacts/contracts/interfaces/IERC20.sol/IERC20.json");
const provider = ethers.provider;

describe("Flashswap contract", () => {
    let FLASHSWAP, BORROW_AMOUNT, INITIAL_FUND_HUMAN, FUND_AMOUNT, TX_ARBITRAGE, GAS_USED_USD;
    const DECIMALS = 6;
    const USDC_WALE = "0x72a53cdbbcc1b9efa39c834a540550e23463aacb";
    const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    const LINK = "0x514910771AF9Ca656af840dff83E8264EcF986CA";


    const BASE_TOKEN_ADDRESS = USDC;
    const TOKEN_BASE = new ethers.Contract(BASE_TOKEN_ADDRESS, abi, provider);

    beforeEach(async () => {
        //get owner as signer
        [owner] = await ethers.getSigners();

        // ensure that the WALE has a balance 
        const whale_balance = await provider.getBalance(USDC_WALE);
        expect(whale_balance).not.equal("0");

        // Deploy smart contract 
        const FlashSwap = await ethers.getContractFactory("UniswapV2ShushiFlashSwap");
        FLASHSWAP = await FlashSwap.deploy();
        await FLASHSWAP.deployed();

        // Configure Our Borrowing 
        const borrowAmountHuman = "1000";
        BORROW_AMOUNT = ethers.utils.parseUnits(borrowAmountHuman, DECIMALS);

        // Configure Funding - FOR TESTING ONLY 
        INITIAL_FUND_HUMAN = "100";
        FUND_AMOUNT = ethers.utils.parseUnits(INITIAL_FUND_HUMAN, DECIMALS);

        // Fund our Contract - FOR TESTING ONLY 
        await impersonateFundErc20(TOKEN_BASE, USDC_WALE, FLASHSWAP.address, INITIAL_FUND_HUMAN);
    });

    describe("Arbitrage Execution", () => {
        it("Ensures the contract is funded", async () => {
            const flashSwapBlance = await FLASHSWAP.getBalanceOfToken(BASE_TOKEN_ADDRESS);

            const flashSwapBalanceHuman = ethers.utils.formatUnits(flashSwapBlance, DECIMALS);

            console.log(flashSwapBalanceHuman);

            expect(Number(flashSwapBalanceHuman)).to.equal(Number(INITIAL_FUND_HUMAN))
        });

        it("Execute's arbitrage", async () => {
            TX_ARBITRAGE = await FLASHSWAP.startArbitrage(BASE_TOKEN_ADDRESS, BORROW_AMOUNT);

            assert(TX_ARBITRAGE);

            // // Print balance of USDC
            const contractBalanceUSDC = await FLASHSWAP.getBalanceOfToken(USDC);
            const contractBalanceUSDCHuman = Number(ethers.utils.formatUnits(contractBalanceUSDC, DECIMALS));
            console.log("Balance of contract, USDC: " , contractBalanceUSDCHuman, contractBalanceUSDC)

            // print balance of LINK 
            const contractBalanceLINK = await FLASHSWAP.getBalanceOfToken(LINK);
            const contractBalanceLINKHuman = Number(ethers.utils.formatUnits(contractBalanceLINK, 18));
            console.log("Balance of contract, LINK: " , contractBalanceLINKHuman)
        });

        it("Outputs gas price", async () => {
            const txReceipt = await provider.getTransactionReceipt(TX_ARBITRAGE.hash);
            const effGasPrice = txReceipt.effectiveGasPrice;
            const txGasUsed = txReceipt.gasUsed;
            const gasUsedETH = effGasPrice * txGasUsed;
            console.log("Total Gas Used: "+ ethers.utils.formatEther(gasUsedETH.toString()) * 1538);
            expect(gasUsedETH).not.equal(0);
        });
    })
})