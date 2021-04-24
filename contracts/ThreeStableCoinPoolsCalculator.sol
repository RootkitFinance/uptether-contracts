// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator to use with ERC31337 AMM pairs
Ensures 100% of accessible funds are backed at all times
*/

import "./IERC20.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./TokensRecoverable.sol";
import "./IFloorCalculator.sol";

contract ThreeStableCoinPoolsCalculator is IFloorCalculator, TokensRecoverable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 immutable rootedToken;
    IERC20 immutable fiatToken;
    address immutable rootedElitePair;
    address immutable rootedBasePair;
    address immutable rootedFiatPair;
    EnumerableSet.AddressSet ignoredAddresses;

    constructor(IERC20 _rootedToken, IERC20 _eliteToken, IERC20 _baseToken, IERC20 _fiatToken, IUniswapV2Factory _uniswapV2Factory)
    {
        rootedToken = _rootedToken;
        fiatToken = _fiatToken;

        rootedElitePair = UniswapV2Library.pairFor(address(_uniswapV2Factory), address(_rootedToken), address(_eliteToken));
        rootedBasePair = UniswapV2Library.pairFor(address(_uniswapV2Factory), address(_rootedToken), address(_baseToken));   
        rootedFiatPair = UniswapV2Library.pairFor(address(_uniswapV2Factory), address(_rootedToken), address(_fiatToken));
    }    

    function setIgnoreAddresses(address ignoredAddress, bool add) public ownerOnly()
    {
        if (add) 
        { 
            ignoredAddresses.add(ignoredAddress); 
        } 
        else 
        { 
            ignoredAddresses.remove(ignoredAddress); 
        }
    }

    function isIgnoredAddress(address ignoredAddress) public view returns (bool)
    {
        return ignoredAddresses.contains(ignoredAddress);
    }

    function ignoredAddressCount() public view returns (uint256)
    {
        return ignoredAddresses.length();
    }

    function ignoredAddressAt(uint256 index) public view returns (address)
    {
        return ignoredAddresses.at(index);
    }

    function ignoredAddressesTotalBalance() public view returns (uint256)
    {
        uint256 total = 0;
        for (uint i = 0; i < ignoredAddresses.length(); i++) 
        {
            total = total.add(rootedToken.balanceOf(ignoredAddresses.at(i)));
        }

        return total;
    }

    function calculateSubFloor(IERC20 baseToken, IERC20 eliteToken) public override view returns (uint256)
    {
        uint256 rootedBalances = rootedToken.balanceOf(rootedElitePair).add(rootedToken.balanceOf(rootedBasePair)).add(rootedToken.balanceOf(rootedFiatPair));
        uint256 stableCoinBalances = eliteToken.balanceOf(rootedElitePair).add(baseToken.balanceOf(rootedBasePair)).add(fiatToken.balanceOf(rootedFiatPair));
        uint256 amountA = rootedToken.totalSupply().sub(rootedBalances).sub(ignoredAddressesTotalBalance());
        uint256 amountB = UniswapV2Library.quote(amountA, rootedBalances, stableCoinBalances);

        uint256 totalExcessInPools = stableCoinBalances.sub(amountB);
        uint256 currentUnbacked = eliteToken.totalSupply().sub(baseToken.balanceOf(address(eliteToken)));
        
        if (currentUnbacked >= totalExcessInPools) { return 0; }

        return totalExcessInPools.sub(currentUnbacked);
    }
}