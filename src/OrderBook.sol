// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OrderBook is ReentrancyGuard {
    uint256 public nextOrderId = 1;

    struct Order {
        uint256 id;
        address trader;
        bool isBuyOrder;
        address tokenBase;
        address tokenQuote;
        uint256 amount;
        uint256 price;
        uint256 timestamp;
    }

    mapping(uint256 => Order) public orders; // Mapping des ordres par ID
    uint256[] public buyOrderIds; // IDs des ordres d'achat
    uint256[] public sellOrderIds; // IDs des ordres de vente

    event OrderPlaced(
        uint256 indexed id,
        address indexed trader,
        bool isBuyOrder,
        address tokenBase,
        address tokenQuote,
        uint256 amount,
        uint256 price
    );

    event OrderTaken(uint256 indexed id, address indexed taker);

    constructor() {
        // Constructor vide car les tokens sont spécifiés lors de la création de chaque ordre
    }


    function placeOrder(
        bool _isBuyOrder,
        address _tokenBase,
        address _tokenQuote,
        uint256 _amount,
        uint256 _price
    ) external nonReentrant {
        require(_amount > 0, "La quantite doit etre superieure a zero");
        require(_price > 0, "Le prix doit etre superieur a zero");
        require(_tokenBase != address(0) && _tokenQuote != address(0), "Adresses de tokens invalides");

        IERC20 base = IERC20(_tokenBase);
        IERC20 quote = IERC20(_tokenQuote);

        uint256 totalCost = (_amount * _price) / 1e18;

        if (_isBuyOrder) {
            // Pour un ordre d'achat, l'utilisateur doit transférer les tokens de paiement au contrat
            require(
                quote.transferFrom(msg.sender, address(this), totalCost),
                "Echec du transfert des tokens de paiement"
            );
        } else {
            // Pour un ordre de vente, l'utilisateur doit transférer les tokens à vendre au contrat
            require(
                base.transferFrom(msg.sender, address(this), _amount),
                "Echec du transfert des tokens a vendre"
            );
        }

        // Créer un nouvel ordre
        Order memory newOrder = Order({
            id: nextOrderId,
            trader: msg.sender,
            isBuyOrder: _isBuyOrder,
            tokenBase: _tokenBase,
            tokenQuote: _tokenQuote,
            amount: _amount,
            price: _price,
            timestamp: block.timestamp
        });

        // Enregistrer l'ordre
        orders[nextOrderId] = newOrder;

        // Ajouter l'ID de l'ordre à la liste appropriée
        if (_isBuyOrder) {
            buyOrderIds.push(nextOrderId);
        } else {
            sellOrderIds.push(nextOrderId);
        }

        emit OrderPlaced(nextOrderId, msg.sender, _isBuyOrder, _tokenBase, _tokenQuote, _amount, _price);

        nextOrderId++;
    }


    function takeOrder(uint256 _orderId) external nonReentrant {
        Order storage order = orders[_orderId];
        require(order.amount > 0, "Ordre invalide ou deja execute");

        IERC20 base = IERC20(order.tokenBase);
        IERC20 quote = IERC20(order.tokenQuote);

        uint256 totalCost = (order.amount * order.price) / 1e18;

        if (order.isBuyOrder) {
            // L'ordre est un achat, le preneur doit fournir les tokens à vendre
            require(
                base.transferFrom(msg.sender, order.trader, order.amount),
                "Echec du transfert des tokens a vendre"
            );
            // Transférer les tokens de paiement au preneur
            require(
                quote.transfer(msg.sender, totalCost),
                "Echec du transfert des tokens de paiement"
            );
        } else {
            // L'ordre est une vente, le preneur doit fournir les tokens de paiement
            require(
                quote.transferFrom(msg.sender, order.trader, totalCost),
                "Echec du transfert des tokens de paiement"
            );
            // Transférer les tokens à vendre au preneur
            require(
                base.transfer(msg.sender, order.amount),
                "Echec du transfert des tokens a vendre"
            );
        }

        // Supprimer l'ordre
        delete orders[_orderId];
        _removeOrderId(order.isBuyOrder, _orderId);

        emit OrderTaken(_orderId, msg.sender);
    }

    function _removeOrderId(bool _isBuyOrder, uint256 _orderId) internal {
        uint256[] storage orderIds = _isBuyOrder ? buyOrderIds : sellOrderIds;
        for (uint256 i = 0; i < orderIds.length; i++) {
            if (orderIds[i] == _orderId) {
                orderIds[i] = orderIds[orderIds.length - 1];
                orderIds.pop();
                break;
            }
        }
    }

    function getOrder(uint256 _orderId) external view returns (Order memory) {
        return orders[_orderId];
    }

    function getBuyOrderIds() external view returns (uint256[] memory) {
        return buyOrderIds;
    }


    function getSellOrderIds() external view returns (uint256[] memory) {
        return sellOrderIds;
    }
}
