// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

import "./TokensRecoverable.sol";
import "./IERC20.sol";

contract ClaimableAirdrop is TokensRecoverable
{
    IERC20 public immutable claimableToken;
    mapping (address => uint256) public claimableTokens;

    constructor (IERC20 _claimableToken)
    {
        claimableToken = _claimableToken;
    }

    function setAddressesAndAmounts(address[] memory addresses, uint256[] memory amounts) public ownerOnly() 
    {  
        for (uint i = 0; i < addresses.length; i++)
        {
            claimableTokens[addresses[i]] = amounts[i];
        }
    }

    function claim() public
    {
        uint256 claimableAmount = claimableTokens[msg.sender];
        require (claimableAmount > 0, "Nothing to claim");
        claimableToken.transfer(msg.sender, claimableAmount);
        claimableTokens[msg.sender] = 0;
    }
}