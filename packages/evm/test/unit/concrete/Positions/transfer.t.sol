// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {MockPositions} from "../../../mocks/MockPositions.sol";
import {Positions} from "src/core/Positions.sol";

contract TransferTest is Test {
    event Transfer(address indexed from, address indexed to, bytes transferDetailsBytes);

    MockPositions private positions;

    address private immutable cuh;

    constructor() {
        cuh = makeAddr("cuh");
    }

    function setUp() external {
        positions = new MockPositions();
    }

    function test_Transfer_Selector() external {
        assertEq(Positions.transfer_oHLEec.selector, bytes4(keccak256("transfer()")));
    }

    /// @notice Transfer more tokens than you have, causing a revert
    function test_Transfer_Underflow() external {
        vm.pauseGasMetering();

        positions.mint(address(this), 0, 1e18);

        vm.expectRevert();
        vm.resumeGasMetering();
        positions.transfer_oHLEec(cuh, Positions.ILRTATransferDetails(0, 1e18 + 1));
    }

    function test_Transfer_Overflow() external {
        vm.pauseGasMetering();

        positions.mint(address(this), 0, 1e18);
        positions.mint(cuh, 0, type(uint128).max);

        vm.expectRevert();
        vm.resumeGasMetering();
        positions.transfer_oHLEec(cuh, Positions.ILRTATransferDetails(0, 1e18));
    }

    function test_Transfer_Full() external {
        vm.pauseGasMetering();

        positions.mint(address(this), 0, 1e18);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(this), cuh, abi.encode(Positions.ILRTATransferDetails(0, 1e18)));

        vm.resumeGasMetering();
        positions.transfer_oHLEec(cuh, Positions.ILRTATransferDetails(0, 1e18));
        vm.pauseGasMetering();

        Positions.ILRTAData memory data = positions.dataOf_cGJnTo(address(this), 0);

        assertEq(data.balance, 0);

        data = positions.dataOf_cGJnTo(cuh, 0);

        assertEq(data.balance, 1e18);

        vm.resumeGasMetering();
    }

    function test_Transfer_PartialCold() external {
        vm.pauseGasMetering();

        positions.mint(address(this), 0, 1e18);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(this), cuh, abi.encode(Positions.ILRTATransferDetails(0, 0.5e18)));

        vm.resumeGasMetering();
        positions.transfer_oHLEec(cuh, Positions.ILRTATransferDetails(0, 0.5e18));
        vm.pauseGasMetering();

        Positions.ILRTAData memory data = positions.dataOf_cGJnTo(address(this), 0);

        assertEq(data.balance, 0.5e18);

        data = positions.dataOf_cGJnTo(cuh, 0);

        assertEq(data.balance, 0.5e18);

        vm.resumeGasMetering();
    }

    function test_Transfer_PartialHot() external {
        vm.pauseGasMetering();

        positions.mint(address(this), 0, 1e18);
        positions.mint(cuh, 0, 1e18);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(this), cuh, abi.encode(Positions.ILRTATransferDetails(0, 0.5e18)));

        vm.resumeGasMetering();
        positions.transfer_oHLEec(cuh, Positions.ILRTATransferDetails(0, 0.5e18));
        vm.pauseGasMetering();

        Positions.ILRTAData memory data = positions.dataOf_cGJnTo(address(this), 0);

        assertEq(data.balance, 0.5e18);

        data = positions.dataOf_cGJnTo(cuh, 0);

        assertEq(data.balance, 1.5e18);

        vm.resumeGasMetering();
    }
}
