App = {
    web3Provider: null,
    contracts: {},
    oneEther: 1e18,

    init: function() {
        return App.initWeb3();
    },

    initWeb3: function() {

        if (window.web3) {
            App.web3Provider = window.web3.currentProvider;
        }
        else {
            App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
        }
        web3 = new Web3(App.web3Provider);

        return App.initContract();
    },

    initContract: function() {
        $.getJSON('CoinFlipping.json', function(data) {
            // Get the necessary contract artifact file and instantiate it with truffle-contract.
            var CoinFlippingArtifact = data;
            App.contracts.CoinFlipping = TruffleContract(CoinFlippingArtifact);

            // Set the provider for our contract.
            App.contracts.CoinFlipping.setProvider(App.web3Provider);

            // Use our contract to retrieve and mark the adopted pets.
            return App.render();
        });

        return App.bindEvents();
    },

    bindEvents: function() {
        $(document).on('click', '#update', App.updatePlayers);
        $(document).on('click', '#withdrawBtn', App.withdraw);
        $(document).on('click', '#startGame', App.startGame);
        $(document).on('click', '#checkWinner', App.checkWinner);
        $(document).on('click', '#reset', App.resetGame);
        $(document).on('click', '#bankerCheckGameHistory', App.bankerCheckGameHistory);
    },

    render: function() {
        var coinFlippingInstance;
        web3.eth.getAccounts(function(error, accounts){
            if(error){
                console.log(error);
            }
            var account = accounts[0];
            App.contracts.CoinFlipping.deployed().then(function(instance){
                coinFlippingInstance = instance;
                return coinFlippingInstance.whoAmI.call({from: account});
            }).then(function (result) {
                var resultNum = result.c[0];
                if(resultNum === 0){
                    window.location.href = "index.html";
                }
                else if(resultNum === 1){
                    window.location.href = "player.html";
                }
                else{
                    return App.query();
                }
            }).catch(function (error) {
                console.log(error.message);
            });
        });
    },

    query: function () {
        var coinFlippingInstance;
        web3.eth.getAccounts(function (error, accounts) {
            if (error) {
                console.log(error);
            }

            var account = accounts[0];
            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.queryByBanker.call({from: account});
            }).then(function (result) {
                var balance = ((result[1].c[0] * 1e14 + result[1].c[0]) / App.oneEther).toFixed(2);
                $("#username").text(result[0]);
                $("#balance").text(balance);
                return coinFlippingInstance.getPlayers.call({from: account});
            }).then(function (result) {
                var address1 = result[0]==="0x0000000000000000000000000000000000000000" ? "null" : result[0];
                var address2 = result[1]==="0x0000000000000000000000000000000000000000" ? "null" : result[1];
                $("#username1").text(result[2]);
                $("#username2").text(result[3]);
                $("#address1").text(address1);
                $("#address2").text(address2);
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    updatePlayers: function(event){
        event.preventDefault();

        var coinFlippingInstance;

        web3.eth.getAccounts(function (error, accounts) {
            if(error){
                console.log(error);
            }

            var account = accounts[0];
            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.getPlayers({from: account});
            }).then(function (result) {
                var address1 = result[0]==="0x0000000000000000000000000000000000000000" ? "null" : result[0][0];
                var address2 = result[1]==="0x0000000000000000000000000000000000000000" ? "null" : result[0][1];
                $("#username1").text(result[2]);
                $("#username2").text(result[3]);
                $("#address1").text(address1);
                $("#address2").text(address2);
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    withdraw: function(event) {
        event.preventDefault();

        var amount = parseFloat($('#withdrawNum').val()) * App.oneEther;
        var coinFlippingInstance;

        web3.eth.getAccounts(function(error, accounts){
            if(error){
                console.log(error);
            }

            var account = accounts[0];
            App.contracts.CoinFlipping.deployed().then(function(instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.withdraw(amount, {from: account});
            }).then(function(result) {
                alert('Withdraw Successful!');
                return coinFlippingInstance.query.call({from: account});
            }).then(function (result) {
                var balance = ((result[1].c[0] * 1e14 + result[1].c[0]) / App.oneEther).toFixed(2);
                $("#balance").text(balance);
                $('#withdrawNum').attr("value", "");
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    startGame: function(event) {
        event.preventDefault();

        var coinFlippingInstance;

        web3.eth.getAccounts(function (error, accounts) {
            if(error){
                console.log(error);
            }

            var account = accounts[0];

            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.startGame({from: account});
            }).then(function (result) {
                alert("Start Successful!");
                $("#gameState").text(" seconds left! Game Ongoing...");
                $("#startGame").attr("disabled", true);
                var limit = 60;
                var set = setInterval(function () {
                    $("#startGame").val(--limit);
                }, 1000);
                setTimeout(function () {
                    $("#startGame").attr("disabled", false).val("START GAME");
                    $("gameState").text("Game Not ongoing");
                    clearInterval(set);
                }, 60000);
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    checkWinner: function (event) {
        event.preventDefault();

        var coinFlippingInstance;

        web3.eth.getAccounts(function (error, accounts) {
            if(error){
                console.log(error);
            }

            var account = accounts[0];

            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.checkWinner({from: account});
            }).then(function (result) {
                return coinFlippingInstance.getWinner.call({from: account});
            }).then(function (winner) {
                $("#winner").text(winner);
                $("#reset").attr("disabled", false);
                $("#resetState").text("Can Reset Now");
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    resetGame: function(event) {
        event.preventDefault();

        var coinFlippingInstance;

        web3.eth.getAccounts(function (error, accounts) {
            if(error){
                console.log(error);
            }

            var account = accounts[0];

            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.clear({from: account});
            }).then(function (winner) {
                alert("Reset Successful!");
                return $(window).load();
            }).then(function () {
                $("#winner").text("Winner");
                $("#reset").attr("disabled", true);
                $("#resetState").text("Cannot Reset");
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    bankerCheckGameHistory: function (event) {

    }

};

$(function() {
    $(window).load(function() {
        App.init();
    });
});
