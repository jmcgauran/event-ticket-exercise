pragma solidity ^0.5.0;

/*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {
    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address owner ;

    constructor() public {
        owner = msg.sender  ;
        eventId = 0;
    }

    uint256 PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint256 eventId;
    uint256 public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string desc;
        string url;
        uint256 totalTickets;
        uint256 sales;
        mapping(address => uint256) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */

    mapping(uint256 => Event) public events;

    event LogEventAdded(
        string desc,
        string url,
        uint256 ticketsAvailable,
        uint256 eventId
    );
    event LogBuyTickets(address buyer, uint256 eventId, uint256 numTickets);
    event LogGetRefund(
        address accountRefunded,
        uint256 eventId,
        uint256 numTickets
    );
    event LogEndSale(address owner, uint256 balance, uint256 eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */

    modifier onlyOwner() {
        require(msg.sender == owner, "ERROR: NOT THE OWNER");
        _;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */

    function addEvent(
        string memory _desc,
        string memory _url,
        uint256 _num
    ) public onlyOwner returns (uint256) {
        // Set the description, URL and ticket number in a new event.
        events[eventId] = Event({
            desc: _desc,
            url: _url,
            totalTickets: _num,
            sales: 0,
            isOpen: true
            
        });
        eventId = eventId + 1;
        emit LogEventAdded(_desc, _url, _num, eventId);
        return (eventId);
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint256 _eventId)
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            bool
        )
    {
        Event storage _event = events[_eventId];
        return (
            _event.desc,
            _event.url,
            _event.totalTickets,
            _event.sales,
            _event.isOpen
        );
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */

    function buyTickets(uint256 _eventId, uint256 _num) public payable {
        require(events[_eventId].isOpen == true);
        require(msg.value >= _num * PRICE_TICKET);
        require(events[_eventId].totalTickets >= _num);

        events[_eventId].buyers[msg.sender] += _num;
        events[_eventId].sales += _num;

        uint256 _cost = _num * PRICE_TICKET;
        uint256 amountToRefund = msg.value - _cost;
        require(amountToRefund > 0); //ensure amountToRefund is greater than 0
        msg.sender.transfer(amountToRefund);

        emit LogBuyTickets(msg.sender, _eventId, _num);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint256 _eventId) public payable {
        // get the events mapping
        Event storage _refundEvent = events[_eventId];
        // check that user is in buyers mapping
        if (_refundEvent.buyers[msg.sender] > 0) {
            // how many tickets did th user buy
            uint256 _amountTixRefunded = _refundEvent.buyers[msg.sender];
            // reduce sold count
            _refundEvent.sales -= _amountTixRefunded;
            uint256 _refundAmount = _amountTixRefunded * PRICE_TICKET;
            // refund sender
            require(_refundAmount > 0); //ensure amountToRefund is greater than 0
            msg.sender.transfer(_refundAmount);
            // emit refund event
            emit LogGetRefund(msg.sender, _eventId, _amountTixRefunded);
        } else {
            revert("ERROR: YOU HAVE NOT BOUGHT TICKETS");
        }
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint256 _eventId)
        public
        view
        returns (uint256)
    {
        // get the events mapping
        Event storage _refundEvent = events[_eventId];
        uint256 _num = _refundEvent.buyers[msg.sender];
        return _num;
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint256 _eventId) public onlyOwner {
        // get the events mapping
        Event storage _refundEvent = events[_eventId];
        _refundEvent.isOpen = false;
        uint256 balance = _refundEvent.sales * PRICE_TICKET;
        msg.sender.transfer(balance);
        emit LogEndSale(owner, balance, _eventId);
    }
}
