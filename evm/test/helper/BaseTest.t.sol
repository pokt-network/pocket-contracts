pragma solidity 0.8.19;

import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "@openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

import "@forge-std/Test.sol";

import {xPOKT} from "@protocol/xPOKT/xPOKT.sol";
import {Addresses} from "@addresses/Addresses.sol";
import {MockERC20} from "@test/mock/MockERC20.sol";
import {MintLimits} from "@protocol/xPOKT/MintLimits.sol";
import {xPOKTDeploy} from "@deployments/xPOKTDeploy.sol";
import {XERC20Lockbox} from "@protocol/xPOKT/XERC20Lockbox.sol";
import {WormholeBridgeAdapter} from "@protocol/xPOKT/WormholeBridgeAdapter.sol";
import {WormholeTrustedSender} from "@protocol/governance/WormholeTrustedSender.sol";
import {ProxyAdmin} from "@openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";

import {SigUtils} from "@test/helper/SigUtils.sol";

contract BaseTest is xPOKTDeploy, Test {
    /// @notice addresses contract, stores all addresses
    Addresses public addresses;

    /// @notice reference to the wormhole bridge adapter
    WormholeBridgeAdapter public wormholeBridgeAdapter;

    /// @notice reference to the wormhole bridge adapter
    WormholeBridgeAdapter public wormholeBridgeAdapterProxy;

    /// @notice lockbox contract
    XERC20Lockbox public xerc20Lockbox;

    /// @notice original token contract
    MockERC20 public wpokt;

    /// @notice logic contract, not initializable
    xPOKT public xpoktLogic;

    /// @notice proxy admin contract
    ProxyAdmin public proxyAdmin;

    /// @notice proxy contract, stores all state
    xPOKT public xpoktProxy;

    /// @notice signature utils contract
    SigUtils public sigUtils;

    /// @notice name of the token
    string public xpoktName = "POKT";

    /// @notice symbol of the token
    string public xpoktSymbol = "POKT";

    /// @notice owner of the token
    address public owner = address(100_000_000);

    /// @notice pause guardian of the token
    address public pauseGuardian = address(1111111111);

    /// @notice wormhole relayer of the WormholeBridgeAdapter
    address public wormholeRelayer = address(2222222222);

    /// @notice duration of the pause
    uint128 public pauseDuration = 10 days;

    /// @notice external chain buffer cap
    uint112 public externalChainBufferCap = 100_000_000 * 1e6;

    /// @notice external chain rate limit per second
    uint112 public externalChainRateLimitPerSecond = 1_000 * 1e6;

    /// @notice wormhole chainid for base chain
    uint16 public chainId = 30;

    string private constant ADDRESSES_PATH = "./addresses/addresses.json";

    function setUp() public virtual {
        addresses = new Addresses(ADDRESSES_PATH);

        if (!addresses.isAddressSet("WPOKT")) {
            wpokt = new MockERC20();
            addresses.addAddress("WPOKT", address(wpokt), true);
        } else {
            wpokt = MockERC20(addresses.getAddress("WPOKT"));
        }

        {
            address proxyAdminAddress = address(new ProxyAdmin());

            (
                address xpoktLogicAddress,
                address xpoktProxyAddress,
                address wormholeAdapterLogic,
                address wormholeAdapterProxy,
                address lockboxAddress
            ) = deployEthereumSystem(address(wpokt), proxyAdminAddress);

            xpoktProxy = xPOKT(xpoktProxyAddress);
            xpoktLogic = xPOKT(xpoktLogicAddress);
            proxyAdmin = ProxyAdmin(proxyAdminAddress);
            xerc20Lockbox = XERC20Lockbox(lockboxAddress);
            wormholeBridgeAdapter = WormholeBridgeAdapter(wormholeAdapterLogic);
            wormholeBridgeAdapterProxy = WormholeBridgeAdapter(
                wormholeAdapterProxy
            );

            vm.label(xpoktLogicAddress, "xPOKT Logic");
            vm.label(xpoktProxyAddress, "xPOKT Proxy");
            vm.label(proxyAdminAddress, "Proxy Admin");
            vm.label(lockboxAddress, "Lockbox");
            vm.label(pauseGuardian, "Pause Guardian");
            vm.label(owner, "Owner");
            vm.label(pauseGuardian, "Pause Guardian");
            vm.label(address(wormholeAdapterLogic), "WormholeAdapterLogic");
            vm.label(
                address(wormholeBridgeAdapterProxy),
                "WormholeAdapterProxy"
            );
        }

        MintLimits.RateLimitMidPointInfo[]
            memory newRateLimits = new MintLimits.RateLimitMidPointInfo[](2);

        /// lock box limit
        newRateLimits[0].bufferCap = type(uint112).max;
        newRateLimits[0].bridge = address(xerc20Lockbox);
        newRateLimits[0].rateLimitPerSecond = 0;

        /// wormhole limit
        newRateLimits[1].bufferCap = externalChainBufferCap;
        newRateLimits[1].bridge = address(wormholeBridgeAdapterProxy);
        newRateLimits[1].rateLimitPerSecond = externalChainRateLimitPerSecond;

        /// give wormhole bridge adapter and lock box a rate limit
        initializeXPokt(
            address(xpoktProxy),
            xpoktName,
            xpoktSymbol,
            owner,
            newRateLimits,
            pauseDuration,
            pauseGuardian
        );

        uint16[] memory testTargets = new uint16[](1);
        testTargets[0] = chainId;

        initializeWormholeAdapter(
            address(wormholeBridgeAdapterProxy),
            address(xpoktProxy),
            owner,
            wormholeRelayer,
            testTargets
        );

        sigUtils = new SigUtils(xpoktProxy.DOMAIN_SEPARATOR());
    }

    /// --------------------------------------------------------
    /// --------------------------------------------------------
    /// ----------- Internal testing helper functions ----------
    /// --------------------------------------------------------
    /// --------------------------------------------------------

    function _lockboxCanBurn(uint112 burnAmount) internal {
        uint256 startingTotalSupply = xpoktProxy.totalSupply();
        uint256 startingWPoktBalance = wpokt.balanceOf(address(this));
        uint256 startingXpoktBalance = xpoktProxy.balanceOf(address(this));

        xpoktProxy.approve(address(xerc20Lockbox), burnAmount);
        xerc20Lockbox.withdraw(burnAmount);

        uint256 endingTotalSupply = xpoktProxy.totalSupply();
        uint256 endingWPoktBalance = wpokt.balanceOf(address(this));
        uint256 endingXpoktBalance = xpoktProxy.balanceOf(address(this));

        assertEq(
            startingTotalSupply - endingTotalSupply,
            burnAmount,
            "incorrect burn amount to totalSupply"
        );
        assertEq(
            endingWPoktBalance - startingWPoktBalance,
            burnAmount,
            "incorrect burn amount to wpokt balance"
        );
        assertEq(
            startingXpoktBalance - endingXpoktBalance,
            burnAmount,
            "incorrect burn amount to xpokt balance"
        );
    }

    function _lockboxCanBurnTo(address to, uint112 burnAmount) internal {
        uint256 startingTotalSupply = xpoktProxy.totalSupply();
        uint256 startingWPoktBalance = wpokt.balanceOf(to);
        uint256 startingXpoktBalance = xpoktProxy.balanceOf(address(this));

        xpoktProxy.approve(address(xerc20Lockbox), burnAmount);
        xerc20Lockbox.withdrawTo(to, burnAmount);

        uint256 endingTotalSupply = xpoktProxy.totalSupply();
        uint256 endingWPoktBalance = wpokt.balanceOf(to);
        uint256 endingXpoktBalance = xpoktProxy.balanceOf(address(this));

        assertEq(
            startingTotalSupply - endingTotalSupply,
            burnAmount,
            "incorrect burn amount to totalSupply"
        );
        assertEq(
            endingWPoktBalance - startingWPoktBalance,
            burnAmount,
            "incorrect burn amount to wpokt balance"
        );
        assertEq(
            startingXpoktBalance - endingXpoktBalance,
            burnAmount,
            "incorrect burn amount to xpokt balance"
        );
    }

    function _lockboxCanMint(uint112 mintAmount) internal {
        wpokt.mint(address(this), mintAmount);
        wpokt.approve(address(xerc20Lockbox), mintAmount);

        uint256 startingTotalSupply = xpoktProxy.totalSupply();
        uint256 startingWPoktBalance = wpokt.balanceOf(address(this));
        uint256 startingXpoktBalance = xpoktProxy.balanceOf(address(this));

        xerc20Lockbox.deposit(mintAmount);

        uint256 endingTotalSupply = xpoktProxy.totalSupply();
        uint256 endingWPoktBalance = wpokt.balanceOf(address(this));
        uint256 endingXpoktBalance = xpoktProxy.balanceOf(address(this));

        assertEq(
            endingTotalSupply - startingTotalSupply,
            mintAmount,
            "incorrect mint amount to totalSupply"
        );
        assertEq(
            startingWPoktBalance - endingWPoktBalance,
            mintAmount,
            "incorrect mint amount to wpokt balance"
        );
        assertEq(
            endingXpoktBalance - startingXpoktBalance,
            mintAmount,
            "incorrect mint amount to xpokt balance"
        );
    }

    function _lockboxCanMintTo(address to, uint112 mintAmount) internal {
        wpokt.mint(address(this), mintAmount);
        wpokt.approve(address(xerc20Lockbox), mintAmount);

        uint256 startingTotalSupply = xpoktProxy.totalSupply();
        uint256 startingWPoktBalance = wpokt.balanceOf(address(this));
        uint256 startingXpoktBalance = xpoktProxy.balanceOf(to);

        xerc20Lockbox.depositTo(to, mintAmount);

        uint256 endingTotalSupply = xpoktProxy.totalSupply();
        uint256 endingWPoktBalance = wpokt.balanceOf(address(this));
        uint256 endingXpoktBalance = xpoktProxy.balanceOf(to);

        assertEq(
            endingTotalSupply - startingTotalSupply,
            mintAmount,
            "incorrect mint amount to totalSupply"
        );
        assertEq(
            startingWPoktBalance - endingWPoktBalance,
            mintAmount,
            "incorrect mint amount to wpokt balance"
        );
        assertEq(
            endingXpoktBalance - startingXpoktBalance,
            mintAmount,
            "incorrect mint amount to xpokt balance"
        );
    }
}
