OrderBook

OrderBook est un contrat intelligent permettant de placer et de prendre des ordres d'achat et de vente pour des tokens ERC20 sur le réseau de test Sepolia d'Ethereum.

Installation
git clone https://github.com/votre-utilisateur/orderbook-project.git

cd orderbook-project

Installer les dépendances :
foundryup : pour se mettre a jour s'y jamais
forge install

Configuration
touch .env

Ajouter les variables d'environnement :
ETH_PRIVATE_KEY=0xVotreCléPrivéeIci
ALCHEMY_API_KEY=VotreCléAlchemyIci ou infura 

Déploiement

Compiler le projet :
forge clean
forge build

Déployer le contrat :

forge script script/OrderBookScript.sol:OrderBookScript \
    --rpc-url https://eth-sepolia.g.alchemy.com/v2/VotreCléAlchemyIci \
    --broadcast \
    --sender 0xvotreAdresse


Utilisation
Interagissez avec le contrat via Remix ou d'autres outils en utilisant l'adresse du contrat déployé.