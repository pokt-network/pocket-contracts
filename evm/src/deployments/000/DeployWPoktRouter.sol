pragma solidity 0.8.19;

import {Deployment} from "@deployments/Deployment.sol";
import {WPOKTRouter} from "@protocol/xPOKT/WPOKTRouter.sol";

contract DeployWPoktRouter is Deployment {
    function _run() internal override {
        address wpoktRouter = address(
            new WPOKTRouter(
                addresses.getAddress("xPOKT_PROXY"),
                addresses.getAddress("WPOKT"),
                addresses.getAddress("xPOKT_LOCKBOX"),
                addresses.getAddress("WORMHOLE_BRIDGE_ADAPTER_PROXY")
            )
        );

        addresses.addAddress("WPOKT_ROUTER", wpoktRouter, true);
    }
}
