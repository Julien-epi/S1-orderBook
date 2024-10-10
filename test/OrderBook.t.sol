// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/OrderBook.sol";
import "../src/MockETH.sol";
import "../src/MockMatic.sol";

contract OrderBookTest is Test {
    OrderBook public orderbook;
    MockMATIC public tokenBase;
    MockETH public tokenQuote;

    address public trader1 = address(0x1);
    address public trader2 = address(0x2);

    uint256 public initialSupply = 1_000_000 * 10**18;

    function setUp() public {
        // Deploi les tokens mock
        tokenBase = new MockMATIC();
        tokenQuote = new MockETH();

        // Distribu des tokens
        tokenBase.transfer(trader1, 100_000 * 10**18);
        tokenQuote.transfer(trader2, 100_000 * 10**18);

        // Deploi le contrat OrderBook
        orderbook = new OrderBook();

        // approuve le contrat pour transférer des tokens
        vm.startPrank(trader1);
        tokenBase.approve(address(orderbook), type(uint256).max);
        tokenQuote.approve(address(orderbook), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(trader2);
        tokenBase.approve(address(orderbook), type(uint256).max);
        tokenQuote.approve(address(orderbook), type(uint256).max);
        vm.stopPrank();
    }

    function testPlaceBuyOrder() public {
        uint256 amount = 1000 * 10**18;
        uint256 price = 2 * 10**18;
        uint256 totalCost = (amount * price) / 1e18;

        vm.startPrank(trader2);

        uint256 balanceBefore = tokenQuote.balanceOf(trader2);

        // ordre d'achat en spécifiant les adresses des tokens
        orderbook.placeOrder(true, address(tokenBase), address(tokenQuote), amount, price);

        // Vérifi que les tokens de paiement ont été transférés
        uint256 balanceAfter = tokenQuote.balanceOf(trader2);
        assertEq(balanceBefore - balanceAfter, totalCost);

        // Vérifi que l'ordre a été créé
        OrderBook.Order memory order = orderbook.getOrder(1);
        assertEq(order.trader, trader2);
        assertTrue(order.isBuyOrder);
        assertEq(order.tokenBase, address(tokenBase));
        assertEq(order.tokenQuote, address(tokenQuote));
        assertEq(order.amount, amount);
        assertEq(order.price, price);

        vm.stopPrank();
    }

    function testTakeBuyOrder() public {
        // Trader2 place un ordre d'achat
        uint256 amount = 1000 * 10**18;
        uint256 price = 2 * 10**18;

        vm.startPrank(trader2);
        orderbook.placeOrder(true, address(tokenBase), address(tokenQuote), amount, price);
        vm.stopPrank();

        // Trader1 prend l'ordre d'achat
        vm.startPrank(trader1);

        uint256 balanceBaseBefore = tokenBase.balanceOf(trader1);
        uint256 balanceQuoteBefore = tokenQuote.balanceOf(trader1);

        orderbook.takeOrder(1);

        uint256 balanceBaseAfter = tokenBase.balanceOf(trader1);
        uint256 balanceQuoteAfter = tokenQuote.balanceOf(trader1);

        // Vérifi que les tokens ont été transférés correctement
        assertEq(balanceBaseBefore - balanceBaseAfter, amount);
        uint256 totalCost = (amount * price) / 1e18;
        assertEq(balanceQuoteAfter - balanceQuoteBefore, totalCost);

        vm.stopPrank();
    }

    function testPlaceSellOrder() public {
        uint256 amount = 500 * 10**18;
        uint256 price = 3 * 10**18;

        vm.startPrank(trader1);

        uint256 balanceBefore = tokenBase.balanceOf(trader1);

        // ordre de vente en spécifiant les adresses des tokens
        orderbook.placeOrder(false, address(tokenBase), address(tokenQuote), amount, price);

        // Vérifi que les tokens à vendre ont été transférés
        uint256 balanceAfter = tokenBase.balanceOf(trader1);
        assertEq(balanceBefore - balanceAfter, amount);

        // Vérifi que l'ordre a été créé
        OrderBook.Order memory order = orderbook.getOrder(1);
        assertEq(order.trader, trader1);
        assertFalse(order.isBuyOrder);
        assertEq(order.tokenBase, address(tokenBase));
        assertEq(order.tokenQuote, address(tokenQuote));
        assertEq(order.amount, amount);
        assertEq(order.price, price);

        vm.stopPrank();
    }

    function testTakeSellOrder() public {
        // Trader1 place un ordre de vente
        uint256 amount = 500 * 10**18;
        uint256 price = 3 * 10**18;

        vm.startPrank(trader1);
        orderbook.placeOrder(false, address(tokenBase), address(tokenQuote), amount, price);
        vm.stopPrank();

        // Trader2 prend l'ordre de vente
        vm.startPrank(trader2);

        uint256 balanceBaseBefore = tokenBase.balanceOf(trader2);
        uint256 balanceQuoteBefore = tokenQuote.balanceOf(trader2);

        orderbook.takeOrder(1);

        uint256 balanceBaseAfter = tokenBase.balanceOf(trader2);
        uint256 balanceQuoteAfter = tokenQuote.balanceOf(trader2);

        // Vérifi que les tokens ont été transférés
        assertEq(balanceBaseAfter - balanceBaseBefore, amount);
        uint256 totalCost = (amount * price) / 1e18;
        assertEq(balanceQuoteBefore - balanceQuoteAfter, totalCost);

        vm.stopPrank();
    }

    function testCannotTakeNonexistentOrder() public {
        vm.startPrank(trader1);
        vm.expectRevert("Ordre invalide ou deja execute");
        orderbook.takeOrder(999);
        vm.stopPrank();
    }

    function testCannotPlaceOrderWithZeroAmount() public {
        vm.startPrank(trader1);
        vm.expectRevert("La quantite doit etre superieure a zero");
        orderbook.placeOrder(true, address(tokenBase), address(tokenQuote), 0, 1 * 10**18);
        vm.stopPrank();
    }

    function testCannotPlaceOrderWithZeroPrice() public {
        vm.startPrank(trader1);
        vm.expectRevert("Le prix doit etre superieur a zero");
        orderbook.placeOrder(true, address(tokenBase), address(tokenQuote), 1000 * 10**18, 0);
        vm.stopPrank();
    }
}
