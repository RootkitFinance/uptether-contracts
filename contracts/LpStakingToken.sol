// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./IERC31337.sol";
import "./TokensRecoverable.sol";
import "./IUniswapV2Router02.sol";

contract LpStakingToken is ERC20("upUSDT LP Staking", "xLpUpUSDT"), TokensRecoverable
{
    using SafeMath for uint256;
   
    IERC20 public immutable baseEliteLpToken;
    IERC31337 public immutable eliteToken;
    IERC20 public immutable baseToken;
    IUniswapV2Router02 public immutable uniswapV2Router;

    constructor(IERC20 _baseEliteLpToken, IERC31337 _eliteToken, IUniswapV2Router02 _uniswapV2Router) 
    {
        baseEliteLpToken = _baseEliteLpToken;
        eliteToken = _eliteToken;
        baseToken = _eliteToken.wrappedToken();
        uniswapV2Router = _uniswapV2Router;
    }

    // Stake baseEliteLpToken, get staking shares
    function stake(uint256 amount) public 
    {
        uint256 totalBaseEliteLp = baseEliteLpToken.balanceOf(address(this));
        uint256 totalShares = this.totalSupply();

        if (totalShares == 0 || totalBaseEliteLp == 0) 
        {
            _mint(msg.sender, amount);
        } 
        else 
        {
            uint256 mintAmount = amount.mul(totalShares).div(totalBaseEliteLp);
            _mint(msg.sender, mintAmount);
        }

        baseEliteLpToken.transferFrom(msg.sender, address(this), amount);
    }

    // Unstake shares, claim back baseEliteLpToken
    function unstake(uint256 share) public 
    {
        uint256 totalShares = this.totalSupply();
        uint256 unstakeAmount = share.mul(baseEliteLpToken.balanceOf(address(this))).div(totalShares);

        _burn(msg.sender, share);
        baseEliteLpToken.transfer(msg.sender, unstakeAmount);
    }

    function compoundLiquidity() public
    {
        uint256 baseBalance = baseToken.balanceOf(address(this));
        uint256 eliteBalance = eliteToken.balanceOf(address(this));

        if (baseBalance < eliteBalance) 
        {
            eliteToken.withdrawTokens(eliteBalance/2);
        }

        uniswapV2Router.addLiquidity(address(baseToken), address(eliteToken), baseToken.balanceOf(address(this)), eliteToken.balanceOf(address(this)), 0, 0, address(this), block.timestamp);
    }

    function canRecoverTokens(IERC20 token) internal override view returns (bool) 
    { 
        return address(token) != address(this) && address(token) != address(baseEliteLpToken); 
    }
}