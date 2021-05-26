// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./ERC31337.sol";
import "./IERC20.sol";

contract EliteToken is ERC31337
{
    constructor (IERC20 _wrappedToken) ERC31337(_wrappedToken, "eliteTether", "eTether")
    {
    }
}