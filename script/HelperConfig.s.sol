//SPDC-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2600e8;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;

    struct NetworkConfig {
        address priceFeed;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = createOrGetAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaEthConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaEthConfig;
    }

    function createOrGetAnvilEthConfig() public returns (NetworkConfig memory) {
        // vm.startBroadcast();
        MockV3Aggregator mockV3PriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        // vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockV3PriceFeed)
        });
        return anvilConfig;
    }
}
