// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockNatsuToken {
    mapping(address => uint256) public balanceOf;
    string public name = unicode"Mock NatsunoせいCoin";
    string public symbol = "mNATSU";
    uint8 public decimals = 18;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function burnFrom(address from, uint256 amount) external {
        require(balanceOf[from] >= amount, "insufficient balance");
        balanceOf[from] -= amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}