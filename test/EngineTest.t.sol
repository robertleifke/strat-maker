// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {EngineHelper} from "./helpers/EngineHelper.sol";
import {
    createCommands,
    createInputs,
    pushCommands,
    pushInputs,
    addLiquidityCommand,
    removeLiquidityCommand,
    swapCommand
} from "./helpers/Utils.sol";

import {Engine} from "src/core/Engine.sol";
import {Positions} from "src/core/Positions.sol";
import {Pairs} from "src/core/Pairs.sol";

contract EngineTest is Test, EngineHelper {
    event PairCreated(address indexed token0, address indexed token1, int24 strikeInitial);

    function setUp() external {
        _setUp();
    }

    function testCreatePair() external {
        Engine.Commands[] memory commands = new Engine.Commands[](1);
        commands[0] = Engine.Commands.CreatePair;

        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(Engine.CreatePairParams(address(1), address(2), 1));

        engine.execute(address(0), commands, inputs, 0, 0, bytes(""));

        (, int24 strikeCurrent, uint8 initialized) = engine.getPair(address(1), address(2));
        assertEq(initialized, 1);
        assertEq(strikeCurrent, 1);
    }

    function testCreatePairBadToken() external {
        Engine.Commands[] memory commands = new Engine.Commands[](1);
        commands[0] = Engine.Commands.CreatePair;
        bytes[] memory inputs = new bytes[](1);

        inputs[0] = abi.encode(Engine.CreatePairParams(address(0), address(1), 1));

        vm.expectRevert(Engine.InvalidTokenOrder.selector);
        engine.execute(address(0), commands, inputs, 0, 0, bytes(""));

        inputs[0] = abi.encode(Engine.CreatePairParams(address(1), address(0), 1));

        vm.expectRevert(Engine.InvalidTokenOrder.selector);
        engine.execute(address(0), commands, inputs, 0, 0, bytes(""));

        inputs[0] = abi.encode(Engine.CreatePairParams(address(2), address(1), 1));

        vm.expectRevert(Engine.InvalidTokenOrder.selector);
        engine.execute(address(0), commands, inputs, 0, 0, bytes(""));

        inputs[0] = abi.encode(Engine.CreatePairParams(address(1), address(1), 1));

        vm.expectRevert(Engine.InvalidTokenOrder.selector);
        engine.execute(address(0), commands, inputs, 0, 0, bytes(""));
    }

    function testCreatePairEmit() external {
        Engine.Commands[] memory commands = new Engine.Commands[](1);
        commands[0] = Engine.Commands.CreatePair;

        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(Engine.CreatePairParams(address(1), address(2), 1));

        vm.expectEmit(true, true, false, true);
        emit PairCreated(address(1), address(2), 1);
        engine.execute(address(0), commands, inputs, 0, 0, bytes(""));
    }

    function testCreatePairDoubleInit() external {
        Engine.Commands[] memory commands = new Engine.Commands[](1);
        commands[0] = Engine.Commands.CreatePair;

        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(Engine.CreatePairParams(address(1), address(2), 0));

        engine.execute(address(0), commands, inputs, 0, 0, bytes(""));

        vm.expectRevert(Pairs.Initialized.selector);
        engine.execute(address(0), commands, inputs, 0, 0, bytes(""));
    }

    function testCreatePairBadStrike() external {
        Engine.Commands[] memory commands = new Engine.Commands[](1);
        commands[0] = Engine.Commands.CreatePair;

        bytes[] memory inputs = new bytes[](1);
        inputs[0] = abi.encode(Engine.CreatePairParams(address(1), address(2), type(int24).max));

        vm.expectRevert(Pairs.InvalidStrike.selector);
        engine.execute(address(0), commands, inputs, 0, 0, bytes(""));
    }

    // function testAddLiquidity() external {
    //     basicCreate();

    //     basicAddLiquidity();
    // }

    // function testRemoveLiquidity() external {
    //     basicCreate();

    //     basicAddLiquidity();

    //     basicRemoveLiquidity();
    // }

    // function testSwap() external {
    //     basicCreate();

    //     basicAddLiquidity();

    //     Engine.Commands[] memory commands = new Engine.Commands[](1);
    //     commands[0] = Engine.Commands.Swap;

    //     bytes[] memory inputs = new bytes[](1);
    //     inputs[0] =
    //         abi.encode(Engine.SwapParams(address(token0), address(token1), Engine.TokenSelector.Token1, 1e18 - 1));

    //     engine.execute(address(this), commands, inputs, 2, 0, bytes(""));
    // }

    // function testGasAddLiquidity() external {
    //     vm.pauseGasMetering();
    //     basicCreate();

    //     Engine.Commands[] memory commands = new Engine.Commands[](1);
    //     commands[0] = Engine.Commands.AddLiquidity;

    //     bytes[] memory inputs = new bytes[](1);
    //     inputs[0] = abi.encode(
    //         Engine.AddLiquidityParams(
    //             address(token0), address(token1), 0, 1, Engine.TokenSelector.LiquidityPosition, 1e18
    //         )
    //     );

    //     vm.resumeGasMetering();

    //     engine.execute(address(this), commands, inputs, 1, 1, bytes(""));
    // }

    // function testGasRemoveLiquidity() external {
    //     vm.pauseGasMetering();
    //     basicCreate();

    //     Engine.Commands[] memory commands = createCommands();
    //     bytes[] memory inputs = createInputs();

    //     (Engine.Commands addCommand, bytes memory addInput) =
    //         addLiquidityCommand(address(token0), address(token1), 0, 1, Engine.TokenSelector.LiquidityPosition,
    // 1e18);

    //     commands = pushCommands(commands, addCommand);
    //     inputs = pushInputs(inputs, addInput);

    //     engine.execute(address(this), commands, inputs, 1, 1, bytes(""));

    //     (Engine.Commands removeCommand, bytes memory removeInput) = removeLiquidityCommand(
    //         address(token0), address(token1), 0, 1, Engine.TokenSelector.LiquidityPosition, -1e18
    //     );

    //     commands[0] = removeCommand;
    //     inputs[0] = removeInput;

    //     vm.resumeGasMetering();

    //     engine.execute(address(this), commands, inputs, 1, 1, bytes(""));
    // }

    // function testGasSwap() external {
    //     vm.pauseGasMetering();
    //     basicCreate();
    //     basicAddLiquidity();

    //     Engine.Commands[] memory commands = new Engine.Commands[](1);
    //     commands[0] = Engine.Commands.Swap;

    //     bytes[] memory inputs = new bytes[](1);
    //     inputs[0] =
    //         abi.encode(Engine.SwapParams(address(token0), address(token1), Engine.TokenSelector.Token1, 1e18 - 1));

    //     vm.resumeGasMetering();

    //     engine.execute(address(this), commands, inputs, 2, 0, bytes(""));
    // }

    // function testGasSwapAndAdd() external {
    //     vm.pauseGasMetering();
    //     basicCreate();
    //     basicAddLiquidity();

    //     Engine.Commands[] memory commands = createCommands();
    //     bytes[] memory inputs = createInputs();

    //     (Engine.Commands _swapCommand, bytes memory swapInput) =
    //         swapCommand(address(token0), address(token1), Engine.TokenSelector.Token0, -0.2e18);

    //     commands = pushCommands(commands, _swapCommand);
    //     inputs = pushInputs(inputs, swapInput);

    //     (Engine.Commands addCommand, bytes memory addInput) =
    //         addLiquidityCommand(address(token0), address(token1), 0, 0, Engine.TokenSelector.Token0, 0.2e18);

    //     commands = pushCommands(commands, addCommand);
    //     inputs = pushInputs(inputs, addInput);

    //     vm.resumeGasMetering();

    //     engine.execute(address(this), commands, inputs, 2, 1, bytes(""));

    //     vm.pauseGasMetering();
    //     assertEq(token0.balanceOf(address(this)), 0);
    //     assertEq(token1.balanceOf(address(this)), 0);
    //     vm.resumeGasMetering();
    // }

    // function testRemoveAndSwap() external {
    //     vm.pauseGasMetering();
    //     basicCreate();
    //     basicAddLiquidity();

    //     Engine.Commands[] memory commands = createCommands();
    //     bytes[] memory inputs = createInputs();

    //     (Engine.Commands addCommand, bytes memory addInput) =
    //         addLiquidityCommand(address(token0), address(token1), -1, 0, Engine.TokenSelector.LiquidityPosition,
    // 1e18);

    //     commands = pushCommands(commands, addCommand);
    //     inputs = pushInputs(inputs, addInput);

    //     engine.execute(address(this), commands, inputs, 1, 1, bytes(""));

    //     (Engine.Commands removeCommand, bytes memory removeInput) =
    //         removeLiquidityCommand(address(token0), address(token1), 0, 0, Engine.TokenSelector.Token0, -0.2e18);

    //     commands[0] = removeCommand;
    //     inputs[0] = removeInput;

    //     (Engine.Commands _swapCommand, bytes memory swapInput) =
    //         swapCommand(address(token0), address(token1), Engine.TokenSelector.Token0, 0.2e18);

    //     commands = pushCommands(commands, _swapCommand);
    //     inputs = pushInputs(inputs, swapInput);

    //     vm.resumeGasMetering();

    //     engine.execute(address(this), commands, inputs, 2, 1, bytes(""));

    //     vm.pauseGasMetering();
    //     assertEq(token0.balanceOf(address(this)), 0);
    //     vm.resumeGasMetering();
    // }
}
