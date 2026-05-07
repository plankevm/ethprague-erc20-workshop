// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PlankDeployer, BuildOptions} from "plank-foundry-deployer/PlankDeployer.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract ERC20Test is Test, PlankDeployer {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    IERC20 public token;

    function setUp() public {
        BuildOptions memory options = initBuildOptions().dependency("erc20", "src");
        token = IERC20(plankDeployFFI("src/ERC20.plk", options));
    }

    function test_deployerHasInitialSupply() public view {
        assertEq(token.balanceOf(address(this)), 1_000_000);
    }

    function test_totalSupply() public view {
        assertEq(token.totalSupply(), 1_000_000);
    }

    function test_totalSupplyStaysConstant() public {
        address bob = makeAddr("bob");
        token.transfer(bob, 100);
        assertEq(token.totalSupply(), 1_000_000);
    }

    function test_balanceOf() public {
        assertEq(token.balanceOf(address(this)), 1_000_000);
        assertEq(token.balanceOf(makeAddr("alice")), 0);
    }

    function test_transfer() public {
        address bob = makeAddr("bob");
        vm.expectEmit();
        emit Transfer(address(this), bob, 100);
        bool success = token.transfer(bob, 100);
        assertTrue(success);
        assertEq(token.balanceOf(address(this)), 999_900);
        assertEq(token.balanceOf(bob), 100);
    }

    function test_transferToSelf() public {
        uint256 balanceBefore = token.balanceOf(address(this));
        bool success = token.transfer(address(this), 100);
        assertTrue(success);
        assertEq(token.balanceOf(address(this)), balanceBefore);
    }

    function test_transferInsufficientBalance() public {
        address bob = makeAddr("bob");
        vm.expectRevert();
        vm.prank(bob);
        token.transfer(address(this), 1);
    }

    function test_approve() public {
        address bob = makeAddr("bob");
        vm.expectEmit();
        emit Approval(address(this), bob, 500);
        bool success = token.approve(bob, 500);
        assertTrue(success);
        assertEq(token.allowance(address(this), bob), 500);
    }

    function test_allowance() public {
        address bob = makeAddr("bob");
        assertEq(token.allowance(address(this), bob), 0);
        token.approve(bob, 100);
        assertEq(token.allowance(address(this), bob), 100);
    }

    function test_transferFrom() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        token.transfer(alice, 1000);

        vm.prank(alice);
        token.approve(bob, 500);

        vm.prank(bob);
        bool success = token.transferFrom(alice, bob, 300);
        assertTrue(success);
        assertEq(token.balanceOf(alice), 700);
        assertEq(token.balanceOf(bob), 300);
        assertEq(token.allowance(alice, bob), 200);
    }

    function test_transferFromWithoutApproval() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        token.transfer(alice, 1000);

        vm.prank(bob);
        vm.expectRevert();
        token.transferFrom(alice, bob, 300);
    }

    function test_transferFromExceedsAllowance() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        token.transfer(alice, 1000);

        vm.prank(alice);
        token.approve(bob, 100);

        vm.prank(bob);
        vm.expectRevert();
        token.transferFrom(alice, bob, 300);
    }

    function test_transferFromInsufficientBalance() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        vm.prank(alice);
        token.approve(bob, 500);

        vm.prank(bob);
        vm.expectRevert();
        token.transferFrom(alice, bob, 300);
    }

    function test_transferEvent() public {
        address bob = makeAddr("bob");
        vm.expectEmit();
        emit Transfer(address(this), bob, 250);
        token.transfer(bob, 250);
    }

    function test_approvalEvent() public {
        address bob = makeAddr("bob");
        vm.expectEmit();
        emit Approval(address(this), bob, 123);
        token.approve(bob, 123);
    }

    function test_transferFromEvent() public {
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        token.transfer(alice, 1000);

        vm.prank(alice);
        token.approve(bob, 500);

        vm.prank(bob);
        vm.expectEmit();
        emit Transfer(alice, bob, 300);
        token.transferFrom(alice, bob, 300);
    }
}
