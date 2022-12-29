// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SalvaCoin is ERC20, ERC20Capped, ERC20Burnable, Ownable {

    
    constructor() ERC20("SalvaCoin", "STCX") ERC20Capped(100000000 * 10**18) {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        super._mint(to, amount);
    }
}
