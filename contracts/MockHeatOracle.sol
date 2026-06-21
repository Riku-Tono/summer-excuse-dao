// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockHeatOracle {
    uint256 public currentTemperature;
    uint256 public cicadaLevel;

    function setTemperature(uint256 temp) external { currentTemperature = temp; }
    function setCicadaLevel(uint256 level) external { cicadaLevel = level; }
}