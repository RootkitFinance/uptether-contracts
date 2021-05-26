// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";
import "./RootedToken.sol";
import "./RootedTransferGate.sol";
import "./IERC31337.sol";
import "./IERC20.sol";

contract RootedRouter is TokensRecoverable
{
    using SafeERC20 for IERC20;

    IERC20 immutable baseToken;
    IERC31337 immutable eliteToken;
    RootedToken immutable rootedToken;
    IUniswapV2Router02 immutable uniswapV2Router;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    constructor (IERC31337 _eliteToken, RootedToken _rootedToken, IUniswapV2Router02 _uniswapV2Router) 
    {
        IERC20 _baseToken = _eliteToken.wrappedToken();
        baseToken = _baseToken;
        eliteToken = _eliteToken;
        rootedToken = _rootedToken;
        uniswapV2Router = _uniswapV2Router;

        _baseToken.safeApprove(address(_uniswapV2Router), uint256(-1));
        _eliteToken.approve(address(_uniswapV2Router), uint256(-1));
        _rootedToken.approve(address(_uniswapV2Router), uint256(-1));
        _baseToken.safeApprove(address(_eliteToken), uint256(-1));
    }

    function rootedToElitePath() private view returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = address(rootedToken);
        path[1] = address(eliteToken);
        return path;
    }

    function eliteToRootedPath() private view returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = address(eliteToken);
        path[1] = address(rootedToken);
        return path;
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external ensure(deadline) 
    {
        if (path[0] == address(rootedToken) && path[1] == address(baseToken))
        {
            swapRootedForElite(amountIn, amountOutMin, to, deadline);
            return;
        }

        if (path[0] == address(baseToken) && path[1] == address(rootedToken))
        {
            swapEliteForRooted(amountIn, amountOutMin, to, deadline);
            return;
        }

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, to, deadline);
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts)
    {
        if (path[0] == address(rootedToken) && path[1] == address(baseToken))
        {
            return uniswapV2Router.getAmountsOut(amountIn, rootedToElitePath());
        }

        if (path[0] == address(baseToken) && path[1] == address(rootedToken))
        {
            return uniswapV2Router.getAmountsOut(amountIn, eliteToRootedPath());
        }

        return uniswapV2Router.getAmountsOut(amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts)
    {
        if (path[0] == address(rootedToken) && path[1] == address(baseToken))
        {
            return uniswapV2Router.getAmountsIn(amountOut, rootedToElitePath());
        }

        if (path[0] == address(baseToken) && path[1] == address(rootedToken))
        {
            return uniswapV2Router.getAmountsIn(amountOut, eliteToRootedPath());
        }

        return uniswapV2Router.getAmountsIn(amountOut, path);
    }

    function swapRootedForElite(
        uint amountIn,
        uint amountOutMin,
        address to,
        uint deadline) private
    {
        RootedTransferGate gate = RootedTransferGate(address(rootedToken.transferGate()));

        // to avoid double taxation
        gate.setUnrestricted(true);
        rootedToken.transferFrom(msg.sender, address(this), amountIn);
        gate.setUnrestricted(false);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, rootedToElitePath(), address(this), deadline);
        eliteToken.withdrawTokens(eliteToken.balanceOf(address(this)));
        baseToken.safeTransfer(to, baseToken.balanceOf(address(this)));
    }

     function swapEliteForRooted(
        uint amountIn,
        uint amountOutMin,
        address to,
        uint deadline) private 
    {
        baseToken.safeTransferFrom(msg.sender, address(this), amountIn);
        eliteToken.depositTokens(amountIn);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, eliteToRootedPath(), to, deadline);
    }
}