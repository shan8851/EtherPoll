// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Script, console} from "forge-std/Script.sol";
import {EtherPoll} from "../src/EtherPoll.sol";

contract DeployEtherPoll is Script {
  EtherPoll public etherPoll;

  function run() external {
    uint256 deployerKey = vm.envUint("PRIVATE_KEY");

    vm.startBroadcast(deployerKey);

    etherPoll = new EtherPoll();

    vm.stopBroadcast();
  }
}
