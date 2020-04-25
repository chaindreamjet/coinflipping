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
        $(document).on('click', '#depositBtn', App.deposit);
        $(document).on('click', '#withdrawBtn', App.withdraw);
        $(document).on('click', '#transferBtn1', App.transferByName);
        $(document).on('click', '#transferBtn2', App.transferByAddress);
        $(document).on('click', '#joinGame', App.joinGame);
        $(document).on('click', '#getNumber', App.getNumber);
        $(document).on('click', '#sendHash', App.sendHash);
        $(document).on('click', '#sendNumber', App.sendNumber);
        $(document).on('click', '#checkWinner', App.checkWinner);
        $(document).on('click', '#checkTransferHistory', App.checkTransferHistory);
        $(document).on('click', '#playerCheckGameHistory', App.playerCheckGameHistory);
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
                else if(resultNum === 2){
                    window.location.href = "banker.html";
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
                return coinFlippingInstance.query.call({from: account});
            }).then(function (result) {
                var balance = ((result[1].c[0] * 1e14 + result[1].c[0]) / App.oneEther).toFixed(2);
                $("#username").text(result[0]);
                $("#balance").text(balance);
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    deposit: function(event) {
        event.preventDefault();
        var amount = parseFloat($('#depositNum').val()) * App.oneEther;
        var coinFlippingInstance;

        web3.eth.getAccounts(function(error, accounts){
            if(error){
                console.log(error);
            }
            var account = accounts[0];
            App.contracts.CoinFlipping.deployed().then(function(instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.deposit({from: account, value: amount});
            }).then(function() {
                alert('Deposit Successful!');
                return coinFlippingInstance.query.call({from: account});
            }).then(function (result) {
                var balance = ((result[1].c[0] * 1e14 + result[1].c[0]) / App.oneEther).toFixed(2);
                $("#balance").text(balance);
                $("#depositNum").val("");
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
                console.log(amount);
                return coinFlippingInstance.withdraw(amount, {from: account});
            }).then(function(result) {
                alert('Withdraw Successful!');
                return coinFlippingInstance.query.call({from: account});
            }).then(function (result) {
                var balance = ((result[1].c[0] * 1e14 + result[1].c[0]) / App.oneEther).toFixed(2);
                $("#balance").text(balance);
                $("#withdrawNum").val("");
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    transferByName: function (event) {
        event.preventDefault();

        var amount = parseFloat($('#transferNum1').val()) * App.oneEther;
        var toName = $('#toName').val();
        var coinFlippingInstance;

        web3.eth.getAccounts(function (error, accounts) {
            if(error){
                console.log(error);
            }
            var account = accounts[0];

            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.transferByName(toName, amount, {from: account});
            }).then(function (result) {
                alert("Transfer Successful!");
                return coinFlippingInstance.query.call({from: account});
            }).then(function (result) {
                var balance = ((result[1].c[0] * 1e14 + result[1].c[0]) / App.oneEther).toFixed(2);
                $("#balance").text(balance);
                $("#transferNum1").val("");
                $("#toName").val("");
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    transferByAddress: function (event) {
        event.preventDefault();

        var amount = parseFloat($('#transferNum2').val()) * App.oneEther;
        var toAddress = $('#toAddress').val();
        var coinFlippingInstance;

        web3.eth.getAccounts(function (error, accounts) {
            if(error){
                console.log(error);
            }
            var account = accounts[0];

            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.transferByAddr(toAddress, amount, {from: account});
            }).then(function (result) {
                alert("Transfer Successful!");
                return coinFlippingInstance.query.call({from: account});
            }).then(function (result) {
                var balance = ((result[1].c[0] * 1e14 + result[1].c[0]) / App.oneEther).toFixed(2);
                $("#balance").text(balance);
                $("#transferNum2").val("");
                $("#toAddress").val("");
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    joinGame: function (event) {
        event.preventDefault();

        var coinFlippingInstance;

        web3.eth.getAccounts(function (error, accounts) {
            if(error){
                console.log(error);
            }
            var account = accounts[0];

            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.joinGame({from: account});
            }).then(function (result) {
                $("#joinState").text("Success! You joined the game!")
                return coinFlippingInstance.query.call({from: account});
            }).then(function (result) {
                var balance = ((result[1].c[0] * 1e14 + result[1].c[0]) / App.oneEther).toFixed(2);
                $("#balance").text(balance);
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    getNumber: function () {
        var numValue;
        var hashValue;
        var pad;
        var encodedNum;

        numValue = Math.round(Math.random() * 1e16);
        pad = '0'.repeat(66 - web3.toHex(numValue).length);
        encodedNum = "0x" + pad + web3.toHex(numValue).slice(2);
        hashValue = web3.sha3(encodedNum, {encoding: 'hex'});

        $("#numValue").val(numValue);
        $("#hashValue").val(hashValue);
    },

    sendHash: function (event) {
        event.preventDefault();

        var hashValue = $('#hashValue').val();
        var coinFlippingInstance;

        web3.eth.getAccounts(function (error, accounts) {
            if(error){
                console.log(error);
            }

            var account = accounts[0];

            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.sendHash(hashValue, {from: account});
            }).then(function (result) {
                alert("Send Hash Successful!");
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    sendNumber: function (event) {
        event.preventDefault();

        var numValue = $('#numValue').val();
        var coinFlippingInstance;

        web3.eth.getAccounts(function (error, accounts) {
            if(error){
                console.log(error);
            }

            var account = accounts[0];

            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.sendNumber(numValue, {from: account});
            }).then(function (result) {
                alert("Send Number Successful!");
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
                return coinFlippingInstance.playerGetWinner.call({from: account});
            }).then(function (win) {
                if(win){
                    $("#winner").text("YOU WIN!");
                }
                else{
                    $("#winner").text("YOU LOSE!");
                }
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    checkTransferHistory: function (event) {
        event.preventDefault();

        var coinFlippingInstance;

        web3.eth.getAccounts(function (error, accounts) {
            if(error){
                console.log(error);
            }

            var account = accounts[0];

            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.checkRecords({from: account});
            }).then(function (result) {
                console.log(result);
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    },

    playerCheckGameHistory: function (event) {
        event.preventDefault();

        var coinFlippingInstance;

        web3.eth.getAccounts(function (error, accounts) {
            if(error){
                console.log(error);
            }

            var account = accounts[0];

            App.contracts.CoinFlipping.deployed().then(function (instance) {
                coinFlippingInstance = instance;
                return coinFlippingInstance.playerCheckHistory.call({from: account});
            }).then(function (result) {
                $("#gameID").text(result[0].c[0]);
                $("#player1").text(result[1]);
                $("#player2").text(result[2]);
                var startTime = new Date(result[3].c[0] * 1000);
                var endTime = new Date(result[4].c[0] * 1000);
                $("#startTime").text(startTime);
                $("#endTime").text(endTime);
                $("#winner2").text(result[5]);
            }).catch(function (err) {
                console.log(err.message);
            });
        });
    }

};

$(function() {
    $(window).load(function() {
        App.init();
    });
});
