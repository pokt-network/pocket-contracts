pragma solidity 0.8.19;

import {Deployment} from "@deployments/Deployment.sol";
import {ProxyAdmin} from "@openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployProxyAdmin is Deployment {
    function _run() internal override {
        if (!addresses.isAddressSet("PROXY_ADMIN")) {
            address proxyAdmin = address(new ProxyAdmin());

            ProxyAdmin(proxyAdmin).transferOwnership(
                addresses.getAddress("GOV_MULTISIG")
            );

            addresses.addAddress("PROXY_ADMIN", proxyAdmin, true);
        }
    }
}
