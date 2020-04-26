App = {
  web3Provider: null,
  contracts: {},

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
      App.contracts.CoinFlipping = TruffleContract(data);

      // Set the provider for our contract.
      App.contracts.CoinFlipping.setProvider(App.web3Provider);

      // Use our contract to retrieve and mark the adopted pets.
      return App.render();
    });

    return App.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '#register', App.register);
  },

  register: function(event) {
    event.preventDefault();

    var username = $('#username').val();
    var address = $('#address').val();

    var coinFlippingInstance;

    web3.eth.getAccounts(function(error, accounts){
      if(error){
        console.log(error);
      }
      var account = accounts[0];
      App.contracts.CoinFlipping.deployed().then(function(instance) {
        coinFlippingInstance = instance;
        return coinFlippingInstance.create(username, address, {from: account});
      }).then(function() {
        alert('Register Successful!');
        window.location.href = "player.html";
      }).catch(function(err) {
        console.log(err.message);
      });
    });
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
        if(resultNum === 1){
          window.location.href = "player.html";
        }
        else if(resultNum === 2){
          window.location.href = "banker.html";
        }
        else{
          $("#address").val(web3.currentProvider.selectedAddress);
        }
      }).catch(function (error) {
        console.log(error.message);
      });
    });
  },
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
