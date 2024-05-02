pragma solidity 0.8.19;

import {Script} from "@forge-std/Script.sol";
import {console} from "@forge-std/Console.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {WPOKTRouter} from "@protocol/xPOKT/WPOKTRouter.sol";
import {WormholeBridgeAdapter} from "@protocol/xPOKT/WormholeBridgeAdapter.sol";
import {Addresses} from "@addresses/Addresses.sol";
import {WormholeChainIds} from "@generated/WormholeChainIds.sol";

contract SendWPoktToBase is Script, WormholeChainIds {
    using SafeERC20 for ERC20;

    Addresses addresses;

    string private constant ADDRESSES_PATH = "./addresses/addresses.json";

    constructor() {
        addresses = new Addresses(ADDRESSES_PATH);
    }

    function run() public {
        address wpoktHolder = addresses.getAddress("DEPLOYER_EOA");

        vm.startBroadcast(wpoktHolder);

        address wpoktRouter = addresses.getAddress("WPOKT_ROUTER");
        address wpokt = addresses.getAddress("WPOKT");
        address wormholeBridgeAdapter = addresses.getAddress(
            "WORMHOLE_BRIDGE_ADAPTER_PROXY"
        );

        bytes32[] memory trustedSenders = WormholeBridgeAdapter(
            wormholeBridgeAdapter
        ).allTrustedSenders(baseSepoliaWormholeChainIds);

        require(trustedSenders.length > 0, "No trusted senders");

        ERC20(wpokt).approve(wpoktRouter, type(uint256).max);

        uint256 bridgeCostValue = WPOKTRouter(wpoktRouter).bridgeCost(
            baseSepoliaWormholeChainId
        );

        console.log("Bridge cost value: %d gwei", bridgeCostValue);

        WPOKTRouter(wpoktRouter).bridgeTo{value: bridgeCostValue}(
            baseSepoliaWormholeChainId,
            10e6
        );

        vm.stopBroadcast();
    }
}
