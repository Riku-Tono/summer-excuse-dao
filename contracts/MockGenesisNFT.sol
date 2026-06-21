// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockGenesisNFT {
    mapping(address => uint256) public balanceOf;

    mapping(address => bool) private sleepCycleBug;
    mapping(address => bool) private legendaryTripBug;
    mapping(address => bool) private walletBug;
    mapping(address => bool) private summerRoot;

    function setBalance(address owner, uint256 bal) external { balanceOf[owner] = bal; }
    function setSleepCycleBug(address owner, bool val) external { sleepCycleBug[owner] = val; }
    function setLegendaryTripBug(address owner, bool val) external { legendaryTripBug[owner] = val; }
    function setWalletBug(address owner, bool val) external { walletBug[owner] = val; }
    function setSummerRoot(address owner, bool val) external { summerRoot[owner] = val; }

    function hasSleepCycleBug(address owner) external view returns (bool) { return sleepCycleBug[owner]; }
    function hasLegendaryTripBug(address owner) external view returns (bool) { return legendaryTripBug[owner]; }
    function hasWalletBug(address owner) external view returns (bool) { return walletBug[owner]; }
    function hasSummerRoot(address owner) external view returns (bool) { return summerRoot[owner]; }
}