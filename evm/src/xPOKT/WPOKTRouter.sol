pragma solidity 0.8.19;

import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {xPOKT} from "@protocol/xPOKT/xPOKT.sol";
import {XERC20Lockbox} from "@protocol/xPOKT/XERC20Lockbox.sol";
import {WormholeBridgeAdapter} from "@protocol/xPOKT/WormholeBridgeAdapter.sol";

/// @notice xPOKT Router Contract that allows users to bridge their WPOKT to xPOKT on the base chain
/// this reduces the amount of transactions needed from 4 to 2 to turn WPOKT into xPOKT
/// 1. approve the router to spend WPOKT
/// 2. call the bridgeTo function
/// This contract is permissionless and ungoverned.
/// If WPOKT is sent to it, it will be lost
/// If xPOKT is sent to it, it will be able to be used by the next user that converts WPOKT to xPOKT
contract WPOKTRouter {
    using SafeERC20 for ERC20;

    /// @notice the xPOKT token
    xPOKT public immutable xpokt;

    /// @notice standard WPOKT token
    ERC20 public immutable wpokt;

    /// @notice xPOKT lockbox to convert wpokt to xpokt
    XERC20Lockbox public immutable lockbox;

    /// @notice wormhole bridge adapter proxy
    WormholeBridgeAdapter public wormholeBridge;

    /// @notice event emitted when WPOKT is bridged to xPOKT
    event BridgeOutSuccess(uint16 chainId, address indexed to, uint256 amount);

    /// @notice initialize the xPOKT router
    /// @param _xpokt the xPOKT token
    /// @param _wpokt the standard POKT token
    /// @param _lockbox the xPOKT lockbox
    /// @param _wormholeBridge the wormhole bridge adapter proxy
    constructor(
        address _xpokt,
        address _wpokt,
        address _lockbox,
        address _wormholeBridge
    ) {
        xpokt = xPOKT(_xpokt);
        wpokt = ERC20(_wpokt);
        lockbox = XERC20Lockbox(_lockbox);
        wormholeBridge = WormholeBridgeAdapter(_wormholeBridge);
    }

    /// @notice returns the cost to mint tokens on the destination chain in native
    function bridgeCost(uint16 chainId) external view returns (uint256) {
        return wormholeBridge.bridgeCost(chainId);
    }

    /// @notice bridge WPOKT to xPOKT on any supported chain
    /// receiver address to receive the xPOKT is msg.sender
    /// @param amount amount of WPOKT to bridge
    function bridgeTo(uint16 chainId, uint256 amount) external payable {
        _bridgeTo(chainId, msg.sender, amount);
    }

    /// @notice bridge WPOKT to xPOKT on any supported chain
    /// @param to address to receive the xPOKT
    /// @param amount amount of WPOKT to bridge
    function bridgeTo(
        uint16 chainId,
        address to,
        uint256 amount
    ) external payable {
        _bridgeTo(chainId, to, amount);
    }

    /// @notice helper function to bridge POKT to xPOKT on any supported chain
    /// @param to address to receive the xPOKT
    /// @param amount amount of WPOKT to bridge
    function _bridgeTo(uint16 chainId, address to, uint256 amount) private {
        uint256 bridgeCostFee = wormholeBridge.bridgeCost(chainId);

        require(
            bridgeCostFee == msg.value,
            "WPOKTRouter: cost not equal to quote"
        );

        /// transfer WPOKT to this contract from the sender
        wpokt.safeTransferFrom(msg.sender, address(this), amount);

        /// approve the lockbox to spend the WPOKT
        wpokt.approve(address(lockbox), amount);

        /// deposit the WPOKT into the lockbox, which credits the router contract the xPOKT
        lockbox.deposit(amount);

        /// get the amount of xPOKT credited to the lockbox
        uint256 xpoktAmount = xpokt.balanceOf(address(this));

        /// approve the wormhole bridge to spend the xPOKT
        xpokt.approve(address(wormholeBridge), xpoktAmount);

        /// bridge the xPOKT to the destination chain
        wormholeBridge.bridge{value: bridgeCostFee}(chainId, xpoktAmount, to);

        emit BridgeOutSuccess(chainId, to, amount);
    }
}
