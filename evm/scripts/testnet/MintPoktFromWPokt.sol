pragma solidity 0.8.19;

import {Script} from "@forge-std/Script.sol";
import {console} from "@forge-std/Console.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {WPOKTRouter} from "@protocol/xPOKT/WPOKTRouter.sol";
import {XERC20Lockbox} from "@protocol/xPOKT/XERC20Lockbox.sol";
import {Addresses} from "@addresses/Addresses.sol";

contract MintPoktFromWPokt is Script {
    using SafeERC20 for ERC20;

    Addresses addresses;

    string private constant ADDRESSES_PATH = "./addresses/addresses.json";

    constructor() {
        addresses = new Addresses(ADDRESSES_PATH);
    }

    function run() public {
        address wpoktHolder = addresses.getAddress("DEPLOYER_EOA");

        vm.startBroadcast(wpoktHolder);

        address wpokt = addresses.getAddress("WPOKT");
        address lockbox = addresses.getAddress("xPOKT_LOCKBOX");

        ERC20(wpokt).approve(lockbox, type(uint256).max);

        // deposit 10 WPOKT to the lockbox, should mint 10 xPOKT
        XERC20Lockbox(lockbox).deposit(1000e6);

        vm.stopBroadcast();
    }
}
