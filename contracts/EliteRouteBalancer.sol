// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./IERC31337.sol";
import "./TokensRecoverable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract EliteRouteBalancer is TokensRecoverable
{
    using SafeMath for uint256;

    IERC20 public immutable tether;
    IERC31337 public immutable elite;
    IERC20 public immutable pair;
    IUniswapV2Router02 public immutable uniswapV2Router;

    mapping (address => bool) public arbitrageurs;

    constructor (IERC20 _tether, IERC31337 _elite, IUniswapV2Router02 _uniswapV2Router)
    {
        tether = _tether;
        elite = _elite;
        IERC20 _pair = IERC20(IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(_tether), address(_elite)));
        pair = _pair;
        uniswapV2Router = _uniswapV2Router;

        _tether.approve(address(_uniswapV2Router), uint256(-1));
        _elite.approve(address(_uniswapV2Router), uint256(-1));
    }   
    
    modifier arbitrageurOnly()
    {
        require(arbitrageurs[msg.sender], "Not an arbitrageur");
        _;
    }

    function setArbitrageur(address arbitrageur, bool allow) public ownerOnly()
    {
        arbitrageurs[arbitrageur] = allow;
    }

    function balanceEliteRoute() public arbitrageurOnly() 
    {
        uint256 eliteInPair = elite.balanceOf(address(pair));
        uint256 tetherInPair = tether.balanceOf(address(pair));

        bool eliteBalanceLarger = eliteInPair > tetherInPair;
        uint256 largerBalance;
        uint256 smallerBalance;
        
        if (eliteBalanceLarger)
        {
            largerBalance = eliteInPair;
            smallerBalance = tetherInPair;
        }
        else
        {
            largerBalance = tetherInPair;
            smallerBalance = eliteInPair;
        }

        uint256 difference = 10000 - smallerBalance.mul(10000).div(largerBalance);
        if (difference <= 100) { return; } 

        uint256 amountIn = (largerBalance - smallerBalance).div(2);
        uint256 tetherBalance = tether.balanceOf(address(this));
        if (amountIn > tetherBalance)
        {
            amountIn = tetherBalance;
        }

        if (eliteBalanceLarger)
        {
           buyElite(amountIn);
        }
        else
        {
           buyTether(amountIn);
        }
    }    

    function buyElite(uint256 amountIn) private
    {        
        address[] memory path = new address[](2);
        path[0] = address(tether);
        path[1] = address(elite);
        uint256[] memory amounts = uniswapV2Router.swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
        elite.withdrawTokens(amounts[1]);
    }

    function buyTether(uint256 amountIn) private
    {
        address[] memory path = new address[](2);
        path[0] = address(elite);
        path[1] = address(tether);
        elite.depositTokens(amountIn);
        uniswapV2Router.swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
    }
}