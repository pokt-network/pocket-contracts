pragma solidity 0.8.19;

import {Script} from "@forge-std/Script.sol";
import {console} from "@forge-std/Console.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {WormholeBridgeAdapter} from "@protocol/xPOKT/WormholeBridgeAdapter.sol";
import {Addresses} from "@addresses/Addresses.sol";
import {WormholeChainIds} from "@generated/WormholeChainIds.sol";

contract SendPoktToBase is Script, WormholeChainIds {
    using SafeERC20 for ERC20;

    Addresses addresses;

    string private constant ADDRESSES_PATH = "./addresses/addresses.json";

    constructor() {
        addresses = new Addresses(ADDRESSES_PATH);
    }

    function run() public {
        address poktHolder = addresses.getAddress("DEPLOYER_EOA");

        vm.startBroadcast(poktHolder);

        address pokt = addresses.getAddress("xPOKT_PROXY");
        address wormholeBridgeAdapter = addresses.getAddress(
            "WORMHOLE_BRIDGE_ADAPTER_PROXY"
        );

        bytes32[] memory trustedSenders = WormholeBridgeAdapter(
            wormholeBridgeAdapter
        ).allTrustedSenders(baseSepoliaWormholeChainIds);

        require(trustedSenders.length > 0, "No trusted senders");

        ERC20(pokt).approve(wormholeBridgeAdapter, type(uint256).max);

        uint256 bridgeCostValue = WormholeBridgeAdapter(wormholeBridgeAdapter)
            .bridgeCost(baseSepoliaWormholeChainId);

        console.log("Bridge cost value: %d gwei", bridgeCostValue);

        // bridge 1 POKT to the base chain
        WormholeBridgeAdapter(wormholeBridgeAdapter).bridge{
            value: bridgeCostValue
        }(baseSepoliaWormholeChainId, 1e6, poktHolder);

        vm.stopBroadcast();
    }
}
