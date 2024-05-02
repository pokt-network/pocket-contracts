pragma solidity 0.8.19;

import {Addresses} from "@addresses/Addresses.sol";
import {Script} from "forge-std/Script.sol";
import {console} from "@forge-std/console.sol";

abstract contract Deployment is Script {
    Addresses addresses;

    string private constant ADDRESSES_PATH = "./addresses/addresses.json";

    constructor() {
        addresses = new Addresses(ADDRESSES_PATH);
    }

    function _run() internal virtual;

    function _deployer() internal view virtual returns (address) {
        return addresses.getAddress("DEPLOYER_EOA");
    }

    function run() public {
        address deployer = _deployer();

        vm.startBroadcast(deployer);

        _run();

        vm.stopBroadcast();

        _printRecordedAddresses();
    }

    function _printRecordedAddresses() private view {
        (
            string[] memory recordedNames,
            ,
            address[] memory recordedAddresses
        ) = addresses.getRecordedAddresses();

        if (recordedNames.length > 0) {
            console.log(
                "\n-------- Addresses added after running deployment --------"
            );
            for (uint256 j = 0; j < recordedNames.length; j++) {
                console.log(
                    '\r{\n          "addr": "%s", ',
                    recordedAddresses[j]
                );
                console.log('        "chainId": %d,', block.chainid);
                console.log('        "isContract": %s%s', true, ",");
                console.log(
                    '        "name": "%s"\n}%s',
                    recordedNames[j],
                    j < recordedNames.length - 1 ? "," : ""
                );
            }
        }

        (
            string[] memory changedNames,
            ,
            ,
            address[] memory changedAddresses
        ) = addresses.getChangedAddresses();

        if (changedNames.length > 0) {
            console.log(
                "\n------- Addresses changed after running deployment --------"
            );

            for (uint256 j = 0; j < changedNames.length; j++) {
                console.log("{\n          'addr': '%s', ", changedAddresses[j]);
                console.log("        'chainId': %d,", block.chainid);
                console.log("        'isContract': %s", true, ",");
                console.log(
                    "        'name': '%s'\n}%s",
                    changedNames[j],
                    j < changedNames.length - 1 ? "," : ""
                );
            }
        }
    }
}
