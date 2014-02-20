package pnp;

import java.net.MalformedURLException;

// see documentation at the main method 
public class Example {
	
	private Client client;
	
	public Example(String host, String user, String password) throws ClientException, MalformedURLException {
		this.client = new Client(host, user, password);
	}
	
	public void simulateUserFundsReceived(String transactionId, String userId, String totalAmount, String userAmount, String gatewayFee) throws ClientException {
		System.out.println("* Funds received from " + userId);
		
		String response = this.client.userFundsReceived(
			transactionId,
			"http://yourapp.com/userFundsReceived/" + transactionId,
			"User Funds Received " + userId,
			userId,
			totalAmount,
			userAmount,
			gatewayFee
		);
		
		System.out.println(response);
	}
	
	public void simulateUserRippleWalletFunded(String transactionId, String userId, String amount) throws ClientException {
		System.out.println("User " + userId + " sent some money to his 'virtual' ripple wallet");
		
		String response = this.client.userRippleWalletFunded(
			transactionId,
			"http://yourapp.com/userRippleWalletFunded/" + transactionId,
			"User Ripple Wallet Funded " + userId,
			userId,
			amount
		);
		
		System.out.println(response);
	}
		
	public void simulateBankToRippleWallet(String transactionId, String amount) throws ClientException {
		System.out.println("Gateway transfered money his ripple wallet");
		
		String response = this.client.bankToRippleWallet(
			transactionId,
			"http://yourapp.com/bankToRippleWallet/" + transactionId,
			"Bank To Ripple Wallet",
			amount
		);
		
		System.out.println(response);
	}
	
	public void simulateUserFundsTransferredOffRippleNetwork(String transactionId, String userId, String amount) throws ClientException {
		System.out.println("User " + userId + " took some of his money out of his virtual ripple wallet");
		
		String response = this.client.userFundsTransferredOffRippleNetwork(
			transactionId,
			"http://yourapp.com/userFundsTransferredOffRippleNetwork/" + transactionId,
			"User Funds Transferred Off Ripple Network " + userId,
			userId,
			amount
		);
		
		System.out.println(response);
	}
		
	public void simulateRippleWalletToBank(String transactionId, String amount) throws ClientException {	
		System.out.println("Gateway transfered money from his ripple wallet to bank");
		
		String response = this.client.rippleWalletToBank(
			transactionId,
			"http://yourapp.com/rippleWalletToBank/" + transactionId,
			"Ripple Wallet To Bank",
			amount
		);
		
		System.out.println(response);
	}
	
	public void simulateUserFundsTransferredOutOfBank(String transactionId, String userId, String totalAmount, String userAmount, String gatewayFee) throws ClientException {
		System.out.println("User " + userId + " withdraw some money");
		
		String response = this.client.userFundsTransferredOutOfBank(
			transactionId,
			"http://yourapp.com/userFundsTransferredOutOfBank/" + transactionId,
			"User Funds Transfered Out Of Bank",
			userId,
			totalAmount,
			userAmount,
			gatewayFee
		);
		
		System.out.println(response);
	}

	/**
	 * This is just an example scenario, where two users add money to the gateway,
	 * then each moves part of the deposited amount to his virtual ripple wallet.
	 * 
	 * The gateway then transfer an amount from its bank account to its ripple
	 * wallet. In this example, the amount corresponds to the sun of the amounts
	 * moved by the two users to theirs virtual ripple wallets. 
	 * 
	 * Then the two users moves some money out of their virtual ripple wallets.
	 * 
	 * This is followed by the gateway transferring money from its ripple wallet
	 * to bank account. The amount hear also corresponds to the amount moved by
	 * the two users.
	 * 
	 * The scenario ends with one of the user withdrawing some money from the
	 * gateway itself.
	 * 
	 * IMPORTANT:
	 * - All the id parameters refer to id's on your application. The mapping of
	 *   this id to the actual Subledger accounts id's are handled inside PnP.
	 *   In other words, you talk to PnP on your own terms.
	 *  
	 * - Transaction Id doesn't need to be an integer, but must be unique for a 
	 *   given event. For example, transaction_id could be '1', 'ASDBC123', or a UUID,
	 *   but if you used transaction_id '1' on event 'userFundsReceived', you can not use
	 *   it again on that event. You can use transaction_id '1' on userRippleWalletFunded 
	 *   although. You will probably just use the transaction id from your own application.
	 *   
	 * - User Id also doens't need to be an email. This id must not change for a given user,
	 *   so if you app allows the user to change his email, use something else as a user id.
	 *   
	 * - Amounts should be given as String to avoid conversions errors, should not contain
	 *   currency sign, should not contain group separator. Decimal places are optional, but
	 *   should use dot as separator when used. We handle up to 12 decimal places.
	 *   Ex: one thousand = 1000 or 1000.00
	 *   Ex: ten and one cent = 10.01
	 *   Ex: ten thousands = 10000.00
	 *   
	 * - PnP runs asynchronously and enqueues requests to handle load, so call to its api should
	 *   return fast, but you will not get an error message if some wrong value was passed.
	 *   To check the outcome of an event, you will have to use the 'trasaction_status' method,
	 *   which runs synchronously, and will tell you if the transaction was already processed,
	 *   and if yes, what was the outcome.
	 *   
	 * - This PnP java client catches any Throwable while communicating with PnP API, and
	 *   encapsulates it in a ClientException, which will have the default message and cause
	 *   attributes, but also the httpCode attribute, which you can check to see if something
	 *   is wrong with the PnP deployment. Remember, this is not a tool to check for errors
	 *   on transaction processing, it only gives hints on communication error.
	 *   
	 * - This example does not handle communication error from your app to PnP, so it should be
	 *   handled by your app. Once it a message is successfully delivered to PnP, then it is
	 *   our job to make sure it gets processed.
	 * 
	 */
	public static void main(String[] args) throws ClientException, MalformedURLException {
		// actual pnp client is instantiated inside Example constructor, and reused on every call
		Example example = new Example("localhost:3000", "pnp", "password");
		
		// users deposited some money
		example.simulateUserFundsReceived("1", "user1@yourapp.com", "100", "89.90", "10.10");
		example.simulateUserFundsReceived("2", "user2@yourapp.com", "50.00", "45", "5");
		
		// users moved some funds to their virtual ripple wallets
		example.simulateUserRippleWalletFunded("1", "user1@yourapp.com", "50");
		example.simulateUserRippleWalletFunded("2", "user2@yourapp.com", "20");
		
		// gateway transfered money from bank to ripple wallet
		example.simulateBankToRippleWallet("1", "70");
		
		// users moved some money back from their virtual ripple wallets
		example.simulateUserFundsTransferredOffRippleNetwork("1", "user1@yourapp.com", "30");
		example.simulateUserFundsTransferredOffRippleNetwork("2", "user2@yourapp.com", "10");
		
		// gateway transfered money from ripple wallet to bank
		example.simulateRippleWalletToBank("1", "40.00");
		
		// user 1 withdraw some money from the gateway itself
		example.simulateUserFundsTransferredOutOfBank("1", "user1@yourapp.com", "60", "55", "5");
	}
}
