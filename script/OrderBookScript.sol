// scripts/OrderBookScript.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {OrderBook} from "../src/OrderBook.sol";

contract OrderBookScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        OrderBook orderbook = new OrderBook();

        // contract address
        console.log(unicode"OrderBook déployé à l'adresse :", address(orderbook));

        vm.stopBroadcast();
    }
}
