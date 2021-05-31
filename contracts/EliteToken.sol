// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./ERC31337.sol";
import "./IERC20.sol";

contract EliteToken is ERC31337
{
    constructor (IERC20 _wrappedToken) ERC31337(_wrappedToken, "Elite Tether", "eUSDT")
    {
        minter = msg.sender; // for migration
    }

    function burn(uint256 amount) public
    {
        _burn(msg.sender, amount);
    }
    
    // for migration
    address public minter;
    bool public minted;
    function mint(uint256 amount) public 
    {
        require(msg.sender == minter, "Not a minter");
        require(!minted, "Already minted");
        _mint(msg.sender, amount);
        minted = true;
    }
}