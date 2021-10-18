// SPDX-License-Identifier: MIT
// pragma solidity >=0.5.16 <0.9.0;
pragma solidity >=0.6.0 <0.9.0;
contract SupplyChain {

  // <owner>

  address public owner;

  // <skuCount>
  uint public skuCount; 

  // <items mapping>
  // !! instructions not on Readme file.. need to check how this is going to be used !!
  mapping (uint => Item) items;

  // <enum State: ForSale, Sold, Shipped, Received>
  enum State {
        ForSale,
        Sold,
        Shipped,
        Received
    }

  // <struct Item: name, sku, price, state, seller, and buyer>
  
  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  /* 
   * Events
   */

  // <LogForSale event: sku arg>
  event LogForSale(uint sku);
  // <LogSold event: sku arg>
  event LogSold(uint sku);
  // <LogShipped event: sku arg>
  event LogShipped(uint sku);
  // <LogReceived event: sku arg>
  event LogReceived(uint sku);

  /* 
   * Modifiers
   */

  // Create a modifer, `isOwner` that checks if the msg.sender is the owner of the contract

  // <modifier: isOwner

  modifier isOwner (address _address) {
    require (owner == _address);
    _;
  }
  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    //refund them after pay for item (why it is before, _ checks for logic before func)
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    //items[_sku].buyer.transfer(amountToRefund);

  }

  // For each of the following modifiers, use what you learned about modifiers
  // to give them functionality. For example, the forSale modifier should
  // require that the item with the given sku has the state ForSale. Note that
  // the uninitialized Item.State is 0, which is also the index of the ForSale
  // value, so checking that Item.State == ForSale is not sufficient to check
  // that an Item is for sale. Hint: What item properties will be non-zero when
  // an Item has been added?

// make sure that items is for sale
  modifier forSale(uint _sku) {
// !!! sku number is passed as parameter, should we use this or the skuCount directly !!!
    require(items[_sku].state == State.ForSale && items[_sku].buyer == address(0));
    _;
  }
 // make sure item state is sold 
  modifier sold(uint _sku) {
   require(items[_sku].state == State.Sold && items[_sku].buyer != address(0));
    _;

  }
  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped && items[_sku].buyer != address(0));
    _;
  }
  modifier received(uint _sku) {
    require(items[_sku].state == State.Received && items[_sku].buyer != address(0));
    _;
  }

// constructor is called once at the time of creation of the contract.. So state variables are initialised once and left there undisturbed.. 
// looks like an anyone callers to contract function can modify the state variables from within the function. so got to make sure that no one else is accessing owner
// variable for update. how clear how ?? need to research this... !!!!

  constructor() public {
    // 1. Set the owner to the transaction sender
    // 2. Initialize the sku count to 0. Question, is this necessary?
    owner = msg.sender;
    skuCount = 0;
  }
////// 1. ADD ITEM
//////
  function addItem(string memory _name, uint _price) public returns (bool) {
    // 1. Create a new item and put in array
    // 2. Increment the skuCount by one
    // 3. Emit the appropriate event
    // 4. return true
    items[skuCount] = Item ({
      name: _name,
      sku: skuCount,
      price: _price,
      seller: payable(msg.sender),
      //initialise to address(0) cos its the genesis address, no private key, hence no one has access
      buyer: payable(address(0)),
      state: State.ForSale
    });
    skuCount += 1;
    emit LogForSale(skuCount);
    return true;

    // hint:
    // items[skuCount] = Item({
    //  name: _name, 
    //  sku: skuCount, 
    //  price: _price, 
    //  state: State.ForSale, 
    //  seller: msg.sender, 
    //  buyer: address(0)
    //});
    //
    //skuCount = skuCount + 1;
    // emit LogForSale(skuCount);
    // return true;
  }

  // Implement this buyItem function. 
  // 1. it should be payable in order to receive refunds
  // 2. this should transfer money to the seller, 
  // 3. set the buyer as the person who called this transaction, 
  // 4. set the state to Sold. 
  // 5. this function should use 3 modifiers to check 
  //    - if the item is for sale, 
  //    - if the buyer paid enough, 
  //    - check the value after the function is called to make 
  //      sure the buyer is refunded any excess ether sent. 
  // 6. call the event associated with this function!

  // function made payable to enable value transfer
  // modifiers item :state is "for sale", buyer paid enuf (Item.price), 
  // ensure anything over price from msg.value is refunded to buyer

//// 2. BUY ITEM
////
  function buyItem(uint sku) public payable forSale(sku) paidEnough(items[sku].price) checkValue(sku)  {

    //at this point msg.sender => buyer ; owner => seller
    //send value => price to seller's account. 

    // 3. set the buyer as the person who called this transaction
    // 4. set the sate to sold
    // (bool sent, ) = owner.call{value: items[sku].price}("");
    // require(sent, "Failed to send Ether");
    items[sku].seller.transfer(items[sku].price);
    items[sku].buyer = payable(msg.sender);
    items[sku].state = State.Sold;
    //log the event data
    emit LogSold(sku);
  }

///// 3. SHIP ITEM
/////
  // 1. Add modifiers to check:
  //    - the item is sold already 
  //    - the person calling this function is the seller. 
  // 2. Change the state of the item to shipped. 
  // 3. call the event associated with this function!
  function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller)  {
    items[sku].state = State.Shipped;
    emit LogShipped(sku);
  }

///// 4. RECEIVE ITEM
///// 

  // 1. Add modifiers to check 
  //    - the item is shipped already 
  //    - the person calling this function is the buyer. 
  // 2. Change the state of the item to received. 
  // 3. Call the event associated with this function!
  function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer)  {
  items[sku].state = State.Received;
  emit LogReceived(sku);
  }

///// 5. FETCH ITEM
/////
  // Uncomment the following code block. it is needed to run tests
  function fetchItem(uint _sku) public view
     returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
   { 
     name = items[_sku].name; 
     sku = items[_sku].sku; 
     price = items[_sku].price; 
     state = uint(items[_sku].state); 
     seller = items[_sku].seller; 
     buyer = items[_sku].buyer; 
     return (name, sku, price, state, seller, buyer); 
   } 
}

