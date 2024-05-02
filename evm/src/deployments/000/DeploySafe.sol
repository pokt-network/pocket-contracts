// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Deployment} from "@deployments/Deployment.sol";
import {SafeSingletonDeployer} from "@safe-singleton/SafeSingletonDeployer.sol";

contract Mock {
    uint256 public value;

    constructor(uint256 startValue) {
        value = startValue;
    }

    function setValue(uint256 value_) public returns (uint256) {
        return value = value_;
    }
}

contract DeploySafe is Deployment {
    function _run() internal override {
        if (!addresses.isAddressSet("GOV_MULTISIG")) {
            address safe = SafeSingletonDeployer.deploy({
                creationCode: type(Mock).creationCode,
                args: abi.encode(1),
                salt: bytes32("0x1234")
            });
            addresses.addAddress("GOV_MULTISIG", safe, true);
        }
    }
}
