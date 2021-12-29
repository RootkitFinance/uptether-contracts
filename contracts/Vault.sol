// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./TokensRecoverable.sol";
import "./IERC31337.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./RootedTransferGate.sol";
import "./IUniswapV2Factory.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IVault.sol";
import "./IFloorCalculator.sol";

contract Vault is TokensRecoverable, IVault
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20; 

    IUniswapV2Router02 immutable uniswapRouter;
    IUniswapV2Factory immutable uniswapFactory;
    IERC20 immutable rooted;
    IERC20 immutable base;
    IERC31337 immutable elite;
    IERC20 rootedEliteLP;
    IFloorCalculator public calculator;
    RootedTransferGate public gate;
    mapping(address => bool) public seniorVaultManagers;

    constructor(IERC20 _base, IERC31337 _elite, IERC20 _rooted, IFloorCalculator _calculator, RootedTransferGate _gate, IUniswapV2Router02 _uniswapRouter) 
    {        
        base = _base;
        elite = _elite;
        rooted = _rooted;
        calculator = _calculator;
        gate = _gate;
        uniswapRouter = _uniswapRouter;
        uniswapFactory = IUniswapV2Factory(_uniswapRouter.factory());
        
        _base.approve(address(_elite), uint256(-1));
        _base.approve(address(_uniswapRouter), uint256(-1));
        _rooted.approve(address(_uniswapRouter), uint256(-1));
        _elite.approve(address(_uniswapRouter), uint256(-1));        
    }

    function setupPool() public ownerOnly() {       
        rootedEliteLP = IERC20(uniswapFactory.getPair(address(elite), address(rooted)));
        rootedEliteLP.approve(address(uniswapRouter), uint256(-1));
    }

    modifier seniorVaultManagerOnly()
    {
        require(seniorVaultManagers[msg.sender], "Not a Senior Vault Manager");
        _;
    }

    // Owner function to enable other contracts or addresses to use Vault
    function setSeniorVaultManager(address manager, bool allow) public ownerOnly()
    {
        seniorVaultManagers[manager] = allow;
    }

    function setCalculatorAndGate(IFloorCalculator _calculator, RootedTransferGate _gate) public ownerOnly()
    {
        calculator = _calculator;
        gate = _gate;
    }

      // Removes liquidity, buys from either pool, sets a temporary dump tax
    function removeBuyAndTax(uint256 amount, uint256 minAmountOut, uint16 tax, uint256 time) public override seniorVaultManagerOnly()
    {
        gate.setUnrestricted(true);
        amount = removeLiq(amount);
        buyRootedToken(amount, minAmountOut);
        gate.setDumpTax(tax, time);
        gate.setUnrestricted(false);
    }

    // Uses value in the controller to buy
    function buyAndTax(uint256 amountToSpend, uint256 minAmountOut, uint16 tax, uint256 time) public override seniorVaultManagerOnly()
    {
        buyRootedToken(amountToSpend, minAmountOut);
        gate.setDumpTax(tax, time);
    }

    // Sweeps the Base token under the floor to this address
    function sweepFloor() public override seniorVaultManagerOnly()
    {
        elite.sweepFloor(address(this));
    }

    function wrapToElite(uint256 baseAmount) public override seniorVaultManagerOnly() 
    {
        elite.depositTokens(baseAmount);
    }

    function unwrapElite(uint256 eliteAmount) public override seniorVaultManagerOnly() 
    {
        elite.withdrawTokens(eliteAmount);
    }

    function addLiquidity(uint256 eliteAmount) public override seniorVaultManagerOnly() 
    {
        gate.setUnrestricted(true);
        uniswapRouter.addLiquidity(address(elite), address(rooted), eliteAmount, rooted.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
        gate.setUnrestricted(false);
    }

    function removeLiquidity(uint256 lpAmount) public override seniorVaultManagerOnly()
    {
        gate.setUnrestricted(true);
        removeLiq(lpAmount);
        gate.setUnrestricted(false);
    }

    function buyRooted(uint256 amountToSpend, uint256 minAmountOut) public override seniorVaultManagerOnly()
    {
        buyRootedToken(amountToSpend, minAmountOut);
    }

    function sellRooted(uint256 amountToSpend, uint256 minAmountOut) public override seniorVaultManagerOnly()
    {
        sellRootedToken(amountToSpend, minAmountOut);
    }

    function removeLiq(uint256 lpAmount) internal returns (uint256)
    {
        (uint256 tokens, ) = uniswapRouter.removeLiquidity(address(elite), address(rooted), lpAmount, 0, 0, address(this), block.timestamp);
        return tokens;
    }

    function buyRootedToken(uint256 amountToSpend, uint256 minAmountOut) internal returns (uint256)
    {
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(amountToSpend, minAmountOut, buyPath(), address(this), block.timestamp);
        return amounts[1];
    }

    function sellRootedToken(uint256 amountToSpend, uint256 minAmountOut) internal returns (uint256)
    {
        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(amountToSpend, minAmountOut, sellPath(), address(this), block.timestamp);
        return amounts[1];
    }

    function buyPath() internal view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(elite);
        path[1] = address(rooted);
        return path;
    }

    function sellPath() internal view returns (address[] memory) 
    {
        address[] memory path = new address[](2);
        path[0] = address(rooted);
        path[1] = address(elite);
        return path;
    }
}
