// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

interface IVault
{  
    function removeBuyAndTax(uint256 amount, uint256 minAmountOut, uint16 tax, uint256 time) external;
    function buyAndTax(uint256 amountToSpend, uint256 minAmountOut, uint16 tax, uint256 time) external;
    function sweepFloor() external;
    function wrapToElite(uint256 baseAmount) external;
    function unwrapElite(uint256 eliteAmount) external;
    function addLiquidity(uint256 eliteAmount) external;
    function removeLiquidity(uint256 lpAmount) external;    
    function buyRooted(uint256 amountToSpend, uint256 minAmountOut) external;
    function sellRooted(uint256 amountToSpend, uint256 minAmountOut) external;   
}