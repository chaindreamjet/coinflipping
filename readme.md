# User Manual

This is the User Manual for the Coin Flipping Game System (CFG).



## 0. Installation

Make sure **NPM** and **Truffle** are installed in your **Linux/Mac**, and **MetaMask** is embedded in your **Chrome**.

In the CoinFlipping directory, run

> truffle compile && truffle migrate

to deploy the contract to the chain, and run

> npm run dev

to open the web UI.



## 1. Users

### 1.1 Register

Open your MetaMask and select one account, reload the page, the UI will automatically get your address:

![image-20200427171144651](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427171144651.png)



Edit your username to log up, note that username is also one's identification, so it is unique.

![image-20200427171221729](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427171221729.png)



The page will automatically jump to *player.html*, and you can see your username and balance on the top left.

![image-20200427182451618](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427182451618.png)



### 1.2. Account Management

#### 1.2.1 Deposit

Input the amount you want to deposit to the CFG wallet and click Deposit,

![image-20200427182244488](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427182244488.png)

After that, your balance will be automatically updated.

![image-20200427182309055](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427182309055.png)

#### 1.2.2 Withdraw

Input the amount you want to withdraw from the CFG wallet and click Deposit, note that you must have enough ether in your CFG wallet,

![image-20200427182347559](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427182347559.png)

Also balance automatically updated.

![image-20200427182400881](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427182400881.png)

#### 1.2.3 Transfer

You can transfer by username:

![image-20200427182606399](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427182606399.png)

and also by address:

![image-20200427182650899](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427182650899.png)

#### 1.2.4 Check Transfer History

Users can get all their transaction information including deposits, withdraws and transfers. Alice's:

![image-20200427182712621](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427182712621.png)

Charles's:

![image-20200427182744783](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427182744783.png)



### 1.3 Game

#### 1.3.1 Join Game

Users join the game just by clicking the button as long as he has >= 1 ether. If it is successful, you will see

![image-20200427172601494](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427172601494.png)

#### 1.3.2 Get Number/ Send Hash/ Send Number

You can get number, salt and their hash at any time since it doesn't call the contract. Once the game is started, the text "Game NOT Ongoing" will be replaced by a 1-minute countdown.

![image-20200427183053322](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427183053322.png)



You must **wait till** the banker started the game and then you can send the hash before the deadline and send the real number and salt to the contract after the deadline.

#### 1.3.5 Check Winner

You must **wait till** the banker checked the winner and transfer the reward to him and then check if you are the winner.

![image-20200427185337214](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427185337214.png)

![image-20200427185312859](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427185312859.png)

#### 1.3.6 Check Game History

You can only check your latest game history information

![image-20200427185520677](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427185520677.png)



# 2. Banker

### 2.1 Check Balance

Banker can see his balance on the top of his page.

 ![banker](D:\Taliyah\HKU\Courses\Sem2\Blockchain\assignment\banker.jpg)

### 2.2 Withdraw 

Banker also can withdraw his reward

![image-20200427184416374](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427184416374.png)

### 2.3 Update Players

Banker can see the current in-game players here.

![image-20200427182917412](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427182917412.png)

### 2.4 Start Game

Once game is started by banker, there is a 1-minute countdown.

![image-20200427182954331](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427182954331.png)

### 2.5 Check Winner

Banker can check the winner name and transfer the reward to him automatically.

![image-20200427185211417](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427185211417.png)

### 2.6 Reset Game

After the game ended, banker should reset the game state for the next game. when he clicks the Reset Game, all will be cleared except the game history

![image-20200427183332038](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427183332038.png)

### 2.7 Check Game History

Banker can check all the game history within one day

![image-20200427185447114](C:\Users\asus\AppData\Roaming\Typora\typora-user-images\image-20200427185447114.png)