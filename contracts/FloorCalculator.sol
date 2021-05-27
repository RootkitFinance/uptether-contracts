// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator to use with ERC31337 AMM pairs
Ensures 100% of accessible funds are backed at all times
*/

import "./IFloorCalculator.sol";
import "./SafeMath.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";
import "./TokensRecoverable.sol";
import "./EnumerableSet.sol";

contract FloorCalculator is IFloorCalculator, TokensRecoverable
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 immutable rootedToken;
    EnumerableSet.AddressSet ignoredAddresses;
    IUniswapV2Factory immutable uniswapV2Factory;

    constructor(IERC20 _rootedToken, IUniswapV2Factory _uniswapV2Factory)
    {
        rootedToken = _rootedToken;
        uniswapV2Factory = _uniswapV2Factory;
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
        address pair = UniswapV2Library.pairFor(address(uniswapV2Factory), address(rootedToken), address(eliteToken));
        uint256 freeRooted = rootedToken.totalSupply().sub(rootedToken.balanceOf(pair)).sub(ignoredAddressesTotalBalance());
        uint256 sellAllProceeds = 0;
        
        if (freeRooted > 0) 
        {
            address[] memory path = new address[](2);
            path[0] = address(rootedToken);
            path[1] = address(eliteToken);
            uint256[] memory amountsOut = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), freeRooted, path);
            sellAllProceeds = amountsOut[1];
        }

        uint256 backingInPool = eliteToken.balanceOf(pair);
        if (backingInPool <= sellAllProceeds) { return 0; }
        uint256 excessInPool = backingInPool - sellAllProceeds;

        uint256 requiredBacking = eliteToken.totalSupply().sub(excessInPool);
        uint256 currentBacking = baseToken.balanceOf(address(eliteToken));
        if (requiredBacking >= currentBacking) { return 0; }
        return currentBacking - requiredBacking;
    }
}