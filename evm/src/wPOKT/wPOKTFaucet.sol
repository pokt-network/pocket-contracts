pragma solidity 0.8.19;

import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";

/// Invariants:
/// Testnet Faucet for getting WPOKT tokens in exchange for SepETH
contract WPOKTFaucet is Ownable2StepUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice The ERC20 token of this contract
    IERC20 public immutable ERC20;

    /// @param wpokt The address of the WPOKT ERC20 contract
    constructor(address wpokt) {
        __Ownable_init();
        _transferOwnership(msg.sender);

        ERC20 = IERC20(wpokt);
    }

    /// @notice Deposit SepETH to mint testnet WPOKT
    function mint() external payable {
        // calculate the value as msg.value / 1e10 -> 0.1 SepETH = 100 WPOKT
        uint256 value = msg.value / 1e10;
        ERC20.safeTransfer(msg.sender, value);
    }

    /// @notice Withdraw all ERC20 tokens
    function withdrawTokens() external onlyOwner {
        ERC20.safeTransfer(owner(), ERC20.balanceOf(address(this)));
    }

    /// @notice Withdraw all ETH
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
